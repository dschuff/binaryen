/*
 * Copyright 2024 WebAssembly Community Group participants
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


#ifndef wasm_analysis_callgraph_h
#define wasm_analysis_callgraph_h

#include "support/small_vector.h"
#include "wasm.h"

namespace wasm::analysis {

struct CGNode {
    Name name;
    Function* func;
    SmallVector<CGNode*, 2> direct_callees;
    SmallVector<CGNode*, 2> indirect_reachables;
};

struct Callgraph {
    std::unordered_map<Name, CGNode> nodes;
};

struct ReachablilitySomething {
    std::vector<bool> reachable;
};

ReachablilitySomething GetReachabilityFor(Name entry);
using EntryPointGroup = std::set<Name>;
void RunCallgraphAnalysis(Module* moudle, std::vector<EntryPointGroup> entry_points, bool verbose);


} // namespace wasm::analysis

#endif // wasm_analysis_callgraph_h