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
 
#include "callgraph.h"
#include "ir/module-splitting.h"
#include "wasm-traversal.h"
#include "wasm-type.h"
#include "wasm.h"
#include <deque>
#include <iostream>
#include <memory>
#include <optional>
#include <unordered_set>

namespace wasm::analysis {


class CallgraphPostwalker : public PostWalker<CallgraphPostwalker> {
 public:
  CallgraphPostwalker(Callgraph* full_graph) :
    full_graph(full_graph) {}

  // Visit a function declaration
  void visitFunction(Function* func) {
    // std::cerr << "Visiting function " << func->name << std::endl;
    CGNode& node = full_graph->nodes[func->name];
    for (const auto& callee : direct_callees) {
      node.direct_callees.push_back(&full_graph->nodes[callee]);
    }
    direct_callees.clear();
    for (const auto& callee : indirect_reachables) {
      node.indirect_reachables.push_back(&full_graph->nodes[callee]);
    }
    indirect_reachables.clear();
  }

  void visitCall(Call* call)  {
    auto result [[ maybe_unused ]] = direct_callees.insert(call->target);
    // if (result.second) std::cerr << " Visiting call from " << getFunction()->name << " to " << call->target << std::endl;
  }

  static bool isTargetReachable(Signature call_sig, Signature target_sig) {
    if (!Type::isSubType(target_sig.results, call_sig.results)) {
      return false;
    }
    if (call_sig.params.size() != target_sig.params.size()) {
      return false;
    }
    for (size_t i = 0; i < call_sig.params.size(); ++i) {
      if (!Type::isSubType(call_sig.params[i], target_sig.params[i])) {
        return false;
      }
    }
    return true;
  }

  void visitCallIndirect(CallIndirect* call) {
    auto signature = call->heapType.getSignature();
    // Find all functions reachable via this type signature
    Module& currModule = *getModule();
    ModuleSplitting::forEachElement(currModule, [&](Name table, Name base, Index offset, Name func) {
      const Signature &target_sig = currModule.getFunction(func)->getSig();
      // std::cerr << "Found element " << func << " sig " << target_sig << std::endl;
      if (table != call->table) {
        return;
      }
      if (!isTargetReachable(signature, target_sig)) {
        return;
      }
      auto result [[ maybe_unused ]] = indirect_reachables.insert(func);
      if (result.second) std::cerr << " Visiting indirect call from " << getFunction()->name << " to " << func << 
        " with signature " << target_sig << std::endl;  
    });
  }

 private:
  std::unordered_set<Name> direct_callees;
  std::unordered_set<Name> indirect_reachables;
  Callgraph* full_graph;
};

void DumpCallgraph(const Callgraph* graph) {
  for (const auto& node : graph->nodes) {
    std::cout << "Node: " << node.first << '\n';
    for (const auto& direct_callee : node.second.direct_callees) {
      std::cout << "  -> " << direct_callee->name << '\n';
    }
    for (const auto& indirect_reachable : node.second.indirect_reachables) {
      std::cout << "  - -> " << indirect_reachable->name << '\n';
    }
  }
}

using ReachableSet = std::vector<const CGNode*>;

ReachableSet GetReachableSubgraph(const Callgraph* graph, EntryPointGroup entrypoints) {
  std::cout << "Reachable subgraph from {";
  for (const auto& entry : entrypoints) {
    std::cout << entry << ", ";
  }
  std::cout << "}\n";

  std::deque<const CGNode*> worklist;
  std::unordered_set<const CGNode*> visited;
  ReachableSet result;
  for (const auto& entry : entrypoints) {
    if (graph->nodes.count(entry) == 0) {
      std::cerr << "Entry point " << entry << " not found in graph\n";
    }
    worklist.push_back(&graph->nodes.at(entry));
  }
  while (!worklist.empty()) {
    const CGNode* node = worklist.front();
    worklist.pop_front();
    visited.insert(node);
    for (const auto& direct_callee : node->direct_callees) {
      if (!visited.count(direct_callee)) {
        worklist.push_back(direct_callee);
      }
    }
    for (const auto& indirect_reachable : node->indirect_reachables) {
      if (!visited.count(indirect_reachable)) {
        worklist.push_back(indirect_reachable);
      }
    }
    std::cout << "Node: " << node->name << '\n';
    result.push_back(node);
  }
  return result;
}

// Analyze a module and build a callgraph
void RunCallgraphAnalysis(Module* module, std::vector<EntryPointGroup> entrypoints) {
  Callgraph full_graph;
  CallgraphPostwalker postwalker(&full_graph);
  for (auto& function : module->functions) {
    CGNode node {function->name, function.get(), {}, {}};
    full_graph.nodes.emplace(function->name, std::move(node));
  }
  postwalker.walkModule(module);
  DumpCallgraph(&full_graph);
  if (entrypoints.empty()) {
    for (auto& ex : module->exports) {
      entrypoints.push_back({ex->name});
    }
  }
  
  for (auto& ep : entrypoints) {
    auto reachable_set = GetReachableSubgraph(&full_graph, ep);
    std::cout << "Entry point beginning with " << *ep.begin() << " has " << ":" << reachable_set.size() <<
    " nodes, " << (float)reachable_set.size() / (float)full_graph.nodes.size() * 100.0f << "%\n";
  }
}

}  // namespace wasm::analysis