/*
 * Copyright 2015 WebAssembly Community Group participants
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "support/file.h"
#include "support/debug.h"
#include "support/path.h"
#include "support/utilities.h"

#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <limits>

#include <vector>
#include <string>
#include <type_traits> // For std::is_same_v
#ifdef BINARYEN_HAS_ZLIB
#include <zlib.h>
#endif // BINARYEN_HAS_ZLIB
#define DEBUG_TYPE "file"

std::vector<char> wasm::read_stdin() {
  BYN_TRACE("Loading stdin...\n");
  std::vector<char> input;
  char c;
  while (std::cin.get(c) && !std::cin.eof()) {
    input.push_back(c);
  }
  return input;
}

template<typename T> struct do_read_stdin { T operator()(); };

template<> std::vector<char> do_read_stdin<std::vector<char>>::operator()() {
  return wasm::read_stdin();
}

template<> std::string do_read_stdin<std::string>::operator()() {
  auto vec = wasm::read_stdin();
  return std::string(vec.begin(), vec.end());
}

template<typename T>
T wasm::read_file(const std::string& filename, Flags::BinaryOption binary) {
  if (filename == "-") {
    return do_read_stdin<T>{}();
  }

  Path::PathString path_obj = wasm::Path::to_path(filename);

#ifdef BINARYEN_HAS_ZLIB
  // First, try to open in binary mode to check for gzip magic bytes
  std::ifstream magic_check_file(path_obj, std::ios::in | std::ios::binary);
  if (!magic_check_file.is_open()) {
    Fatal() << "Failed opening '" << filename << "' for magic number check";
  }

  char magic_bytes[2];
  magic_check_file.read(magic_bytes, 2);

  if (magic_check_file.gcount() == 2 &&
      static_cast<unsigned char>(magic_bytes[0]) == 0x1f &&
      static_cast<unsigned char>(magic_bytes[1]) == 0x8b) {
    // File is gzipped
    magic_check_file.close();
    BYN_TRACE("Loading gzipped '" << filename << "'...\n");

#ifdef USE_WSTRING_PATHS
    gzFile gzfp = gzopen(wasm::Path::wstring_to_string(path_obj).c_str(), "rb");
#else
    gzFile gzfp = gzopen(path_obj.c_str(), "rb");
#endif
    if (!gzfp) {
      Fatal() << "gzopen failed for '" << filename << "'";
    }

    std::vector<char> decompressed_data;
    char chunk_buffer[16384]; // 16KB chunk size
    int gz_errnum;
    int bytes_read;
    while ((bytes_read = gzread(gzfp, chunk_buffer, sizeof(chunk_buffer))) > 0) {
      decompressed_data.insert(decompressed_data.end(), chunk_buffer, chunk_buffer + bytes_read);
    }

    if (bytes_read < 0) {
      const char * error_string = gzerror(gzfp, &gz_errnum);
      gzclose(gzfp);
      Fatal() << "Failed reading gzipped file '" << filename << "': " << error_string << " (errnum: " << gz_errnum << ")";
    }
    gzclose(gzfp);

    if constexpr (std::is_same_v<T, std::string>) {
      return T(decompressed_data.begin(), decompressed_data.end());
    } else { // T is std::vector<char>
      return decompressed_data;
    }
  }
  // Not gzipped, or magic check failed to read 2 bytes.
  magic_check_file.close(); // Close the file opened for magic check
  // Fall through to normal file reading.
#endif // BINARYEN_HAS_ZLIB

  // Normal file reading (either not gzipped, or zlib support is disabled)
  BYN_TRACE("Loading '" << filename << "'...\n");
  std::ifstream infile;
  std::ios_base::openmode flags = std::ifstream::in;
  if (binary == Flags::Binary) {
    flags |= std::ifstream::binary;
  }
  infile.open(path_obj, flags);
  if (!infile.is_open()) {
    Fatal() << "Failed opening '" << filename << "'";
  }
  infile.seekg(0, std::ios::end);
  std::streampos insize = infile.tellg();
  if (uint64_t(insize) >= std::numeric_limits<size_t>::max()) {
    Fatal() << "Failed opening '" << filename
            << "': Input file too large: " << insize
            << " bytes. Try rebuilding in 64-bit mode.";
  }
  T input(static_cast<size_t>(insize), '\0');
  if (static_cast<size_t>(insize) == 0) {
    return input;
  }
  infile.seekg(0);
  infile.read(&input[0], insize);
  if (binary == Flags::Text) {
    size_t chars = static_cast<size_t>(infile.gcount());
    input.resize(chars);
  }
  return input;
}

std::string wasm::read_possible_response_file(const std::string& input) {
  if (input.size() == 0 || input[0] != '@') {
    return input;
  }
  return wasm::read_file<std::string>(input.substr(1), Flags::Text);
}

// Explicit instantiations for the explicit specializations.
template std::string wasm::read_file<>(const std::string&, Flags::BinaryOption);
template std::vector<char> wasm::read_file<>(const std::string&,
                                             Flags::BinaryOption);

wasm::Output::Output(const std::string& filename, Flags::BinaryOption binary)
  : outfile(), out([this, filename, binary]() {
      // Ensure a single return at the very end, to avoid clang-tidy warnings
      // about the types of different returns here.
      std::streambuf* buffer;
      if (filename == "-" || filename.empty()) {
        buffer = std::cout.rdbuf();
      } else {
        BYN_TRACE("Opening '" << filename << "'\n");
        std::ios_base::openmode flags =
          std::ofstream::out | std::ofstream::trunc;
        if (binary == Flags::Binary) {
          flags |= std::ofstream::binary;
        }
        outfile.open(wasm::Path::to_path(filename), flags);
        if (!outfile.is_open()) {
          Fatal() << "Failed opening output file '" << filename
                  << "': " << strerror(errno);
        }
        buffer = outfile.rdbuf();
      }
      return buffer;
    }()) {}

void wasm::copy_file(std::string input, std::string output) {
  std::ifstream src(wasm::Path::to_path(input), std::ios::binary);
  std::ofstream dst(wasm::Path::to_path(output), std::ios::binary);
  dst << src.rdbuf();
}

size_t wasm::file_size(std::string filename) {
  std::ifstream infile(wasm::Path::to_path(filename),
                       std::ifstream::ate | std::ifstream::binary);
  return infile.tellg();
}
