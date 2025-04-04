;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: wasm-opt %s --generate-stack-ir --optimize-stack-ir \
;; RUN:   -all --print-stack-ir | filecheck %s

(module
  ;; CHECK:      (tag $e-i32 (type $2) (param i32))
  (tag $e-i32 (param i32))

  ;; CHECK:      (func $foo (type $0)
  ;; CHECK-NEXT: )
  (func $foo)

  ;; CHECK:      (func $test (type $0)
  ;; CHECK-NEXT:  block $outer
  ;; CHECK-NEXT:   block $l-catch (result i32)
  ;; CHECK-NEXT:    block $l-catch-ref (type $1) (result i32 exnref)
  ;; CHECK-NEXT:     block $l-catch-all
  ;; CHECK-NEXT:      block $l-catch-all-ref (result exnref)
  ;; CHECK-NEXT:       try_table (catch $e-i32 $l-catch) (catch_ref $e-i32 $l-catch-ref) (catch_all $l-catch-all) (catch_all_ref $l-catch-all-ref)
  ;; CHECK-NEXT:        call $foo
  ;; CHECK-NEXT:       end
  ;; CHECK-NEXT:       br $outer
  ;; CHECK-NEXT:      end
  ;; CHECK-NEXT:      throw_ref
  ;; CHECK-NEXT:     end
  ;; CHECK-NEXT:     br $outer
  ;; CHECK-NEXT:    end
  ;; CHECK-NEXT:    tuple.drop 2
  ;; CHECK-NEXT:    br $outer
  ;; CHECK-NEXT:   end
  ;; CHECK-NEXT:   drop
  ;; CHECK-NEXT:  end
  ;; CHECK-NEXT: )
  (func $test
    (block $outer
      (drop
        (block $l-catch (result i32)
          (tuple.drop 2
            (block $l-catch-ref (result i32 exnref)
              (block $l-catch-all
                (throw_ref
                  (block $l-catch-all-ref (result exnref)
                    (try_table (catch $e-i32 $l-catch)
                               (catch_ref $e-i32 $l-catch-ref)
                               (catch_all $l-catch-all)
                               (catch_all_ref $l-catch-all-ref)
                      (call $foo)
                    )
                    (br $outer)
                  )
                )
              )
              (br $outer)
            )
          )
          (br $outer)
        )
      )
    )
  )
)
