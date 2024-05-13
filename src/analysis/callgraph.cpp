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
#include "wasm.h"
#include <deque>
#include <iostream>
#include <unordered_set>
#include <variant>

namespace wasm::analysis {

using ElemsBySig = std::multimap<Signature, Name>;


class CallgraphPostwalker : public PostWalker<CallgraphPostwalker> {
 public:
  CallgraphPostwalker(Callgraph* full_graph, ElemsBySig* elems_by_sig) :
    full_graph(full_graph), elems_by_sig(elems_by_sig) {}

  // Visit a function declaration
  void visitFunction(Function* func) {
    std::cerr << "Visiting function " << func->name << std::endl;
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
    if (result.second) std::cerr << " Visiting call from " << getFunction()->name << " to " << call->target << std::endl;
  }

  void visitCallIndirect(CallIndirect* call) {
    auto signature = call->heapType.getSignature();
    auto reachable_funcs = elems_by_sig->equal_range(signature);
    for (auto it = reachable_funcs.first; it != reachable_funcs.second; ++it) {
      auto& func = it->second;
      auto result [[ maybe_unused ]] = indirect_reachables.insert(func);
      if (result.second) std::cerr << " Visiting indirect call from " << getFunction()->name << " to " << func << 
        " with signature " << it->first << std::endl;
    }
  }

 private:
  std::unordered_set<Name> direct_callees;
  std::unordered_set<Name> indirect_reachables;
  Callgraph* full_graph;
  ElemsBySig* elems_by_sig;
};


ElemsBySig GetElemsBySig(Module* module) {
  // TODO: Handle multiple tables
  ElemsBySig elems_by_sig;
  ModuleSplitting::forEachElement(*module, [&](Name table, Name base, Index offset, Name func) {
    std::cerr << "Found element " << func << " sig " << module->getFunction(func)->getSig() << std::endl;
    elems_by_sig.emplace(module->getFunction(func)->getSig(), func);
  });
  return elems_by_sig;
}

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

ReachableSet GetReachableSubgraph(const Callgraph* graph, Name entry) {
//void DumpReachableSubgraph(const Callgraph* graph, Name entry) {
  std::cout << "Reachable subgraph from " << entry << '\n';
  if (graph->nodes.count(entry) == 0) {
    std::cerr << "Entry point " << entry << " not found in graph\n";
    return {};
  }
  std::deque<const CGNode*> worklist;
  std::unordered_set<const CGNode*> visited;
  ReachableSet result;
  worklist.push_back(&graph->nodes.at(entry));
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
void RunCallgraphAnalysis(Module* module) {
  Callgraph full_graph;
  ElemsBySig elems_by_sig = GetElemsBySig(module);
  CallgraphPostwalker postwalker(&full_graph, &elems_by_sig);
  for (auto& function : module->functions) {
    CGNode node {function->name, function.get(), {}, {}};
    full_graph.nodes.emplace(function->name, std::move(node));
  }
  postwalker.walkModule(module);
  DumpCallgraph(&full_graph);
  for (auto& ex : module->exports) {
    GetReachableSubgraph(&full_graph, ex->name);
  }
}

}  // namespace wasm::analysis