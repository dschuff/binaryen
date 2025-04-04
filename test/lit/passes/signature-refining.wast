;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; RUN: foreach %s %t wasm-opt --signature-refining -all -S -o - | filecheck %s

(module
  ;; $func is defined with an anyref parameter but always called with a $struct,
  ;; and we can specialize the heap type to that. That will both update the
  ;; heap type's definition as well as the types of the parameters as printed
  ;; on the function (which are derived from the heap type).

  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $struct (struct))
  (type $struct (struct))

  ;; CHECK:       (type $1 (func))

  ;; CHECK:       (type $sig (sub (func (param (ref $struct)))))
  (type $sig (sub (func (param anyref))))

  ;; CHECK:      (func $func (type $sig) (param $x (ref $struct))
  ;; CHECK-NEXT: )
  (func $func (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (call $func
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call $func
      (struct.new $struct)
    )
  )
)

(module
  ;; As above, but the call is via call_ref.

  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $struct (struct))
  (type $struct (struct))

  ;; CHECK:       (type $1 (func))

  ;; CHECK:       (type $sig (sub (func (param (ref $struct)))))
  (type $sig (sub (func (param anyref))))

  ;; CHECK:      (elem declare func $func)

  ;; CHECK:      (func $func (type $sig) (param $x (ref $struct))
  ;; CHECK-NEXT: )
  (func $func (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (call_ref $sig
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:   (ref.func $func)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call_ref $sig
      (struct.new $struct)
      (ref.func $func)
    )
  )
)

(module
  ;; A combination of call types, and the LUB is affected by all of them: one
  ;; call uses a nullable $struct, the other a non-nullable i31, so the LUB
  ;; is a nullable eqref.

  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $struct (struct))
  (type $struct (struct))

  ;; CHECK:       (type $1 (func))

  ;; CHECK:       (type $sig (sub (func (param eqref))))
  (type $sig (sub (func (param anyref))))

  ;; CHECK:      (elem declare func $func)

  ;; CHECK:      (func $func (type $sig) (param $x eqref)
  ;; CHECK-NEXT: )
  (func $func (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (local $struct (ref null $struct))
  ;; CHECK-NEXT:  (call $func
  ;; CHECK-NEXT:   (local.get $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call_ref $sig
  ;; CHECK-NEXT:   (ref.i31
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (ref.func $func)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (local $struct (ref null $struct))
    (call $func
      ;; Use a local to avoid a bottom type.
      (local.get $struct)
    )
    (call_ref $sig
      (ref.i31 (i32.const 0))
      (ref.func $func)
    )
  )
)

(module
  ;; Multiple functions with the same heap type. Again, the LUB is in the
  ;; middle, this time the parent $struct and not a subtype.

  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $struct (sub (struct)))

    ;; CHECK:       (type $struct-sub2 (sub $struct (struct)))

    ;; CHECK:       (type $struct-sub1 (sub $struct (struct)))

    ;; CHECK:       (type $3 (func))

    ;; CHECK:       (type $sig (sub (func (param (ref $struct)))))
    (type $sig (sub (func (param anyref))))

    (type $struct (sub (struct)))

    (type $struct-sub1 (sub $struct (struct)))

    (type $struct-sub2 (sub $struct (struct)))
  )

  ;; CHECK:      (func $func-1 (type $sig) (param $x (ref $struct))
  ;; CHECK-NEXT: )
  (func $func-1 (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $func-2 (type $sig) (param $x (ref $struct))
  ;; CHECK-NEXT: )
  (func $func-2 (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $caller (type $3)
  ;; CHECK-NEXT:  (call $func-1
  ;; CHECK-NEXT:   (struct.new_default $struct-sub1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $func-2
  ;; CHECK-NEXT:   (struct.new_default $struct-sub2)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call $func-1
      (struct.new $struct-sub1)
    )
    (call $func-2
      (struct.new $struct-sub2)
    )
  )
)

(module
  ;; As above, but now only one of the functions is called. The other is still
  ;; updated, though, as they share a heap type.

  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $struct (struct))

  ;; CHECK:       (type $1 (func))

  ;; CHECK:       (type $sig (sub (func (param (ref $struct)))))
  (type $sig (sub (func (param anyref))))

  (type $struct (struct))

  ;; CHECK:      (func $func-1 (type $sig) (param $x (ref $struct))
  ;; CHECK-NEXT: )
  (func $func-1 (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $func-2 (type $sig) (param $x (ref $struct))
  ;; CHECK-NEXT: )
  (func $func-2 (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (call $func-1
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call $func-1
      (struct.new $struct)
    )
  )
)

(module
  ;; Define a field in the struct of the signature type that will be updated,
  ;; to check for proper validation after the update.

  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $struct (sub (struct (field (ref $sig)))))

  ;; CHECK:       (type $1 (func))

  ;; CHECK:       (type $sig (sub (func (param (ref $struct) (ref $sig)))))
  (type $sig (sub (func (param anyref funcref))))

  (type $struct (sub (struct (field (ref $sig)))))

  ;; CHECK:      (elem declare func $func)

  ;; CHECK:      (func $func (type $sig) (param $x (ref $struct)) (param $f (ref $sig))
  ;; CHECK-NEXT:  (local $temp (ref null $sig))
  ;; CHECK-NEXT:  (local $3 funcref)
  ;; CHECK-NEXT:  (local.set $3
  ;; CHECK-NEXT:   (local.get $f)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (local.set $3
  ;; CHECK-NEXT:    (local.get $temp)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $func (type $sig) (param $x anyref) (param $f funcref)
    ;; Define a local of the signature type that is updated.
    (local $temp (ref null $sig))
    ;; Do a local.get of the param, to verify its type is valid.
    (drop
      (local.get $x)
    )
    ;; Copy from a funcref local to the formerly funcref param to verify their
    ;; types are still compatible after the update. Note that we will need to
    ;; add a fixup local here, as $f's new type becomes too specific to be
    ;; assigned the value here.
    (local.set $f
      (local.get $temp)
    )
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (call $func
  ;; CHECK-NEXT:   (struct.new $struct
  ;; CHECK-NEXT:    (ref.func $func)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (ref.func $func)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call $func
      (struct.new $struct
        (ref.func $func)
      )
      (ref.func $func)
    )
  )
)

(module
  ;; An unreachable value does not prevent optimization: we will update the
  ;; param to be $struct.

  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $struct (struct))
  (type $struct (struct))

  ;; CHECK:       (type $1 (func))

  ;; CHECK:       (type $sig (sub (func (param (ref $struct)))))
  (type $sig (sub (func (param anyref))))

  ;; CHECK:      (elem declare func $func)

  ;; CHECK:      (func $func (type $sig) (param $x (ref $struct))
  ;; CHECK-NEXT: )
  (func $func (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (call $func
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call_ref $sig
  ;; CHECK-NEXT:   (unreachable)
  ;; CHECK-NEXT:   (ref.func $func)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call $func
      (struct.new $struct)
    )
    (call_ref $sig
      (unreachable)
      (ref.func $func)
    )
  )
)

(module
  ;; When we have only unreachable values, there is nothing to optimize, and we
  ;; should not crash.

  (type $struct (struct))

  ;; CHECK:      (type $sig (sub (func (param anyref))))
  (type $sig (sub (func (param anyref))))

  ;; CHECK:      (type $1 (func))

  ;; CHECK:      (elem declare func $func)

  ;; CHECK:      (func $func (type $sig) (param $x anyref)
  ;; CHECK-NEXT: )
  (func $func (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (call_ref $sig
  ;; CHECK-NEXT:   (unreachable)
  ;; CHECK-NEXT:   (ref.func $func)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call_ref $sig
      (unreachable)
      (ref.func $func)
    )
  )
)

(module
  ;; When we have no calls, there is nothing to optimize, and we should not
  ;; crash.

  (type $struct (struct))

  ;; CHECK:      (type $sig (sub (func (param anyref))))
  (type $sig (sub (func (param anyref))))

  ;; CHECK:      (func $func (type $sig) (param $x anyref)
  ;; CHECK-NEXT: )
  (func $func (type $sig) (param $x anyref)
  )
)

(module
  ;; Test multiple fields in multiple types.
  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $struct (struct))
    (type $struct (struct))

    ;; CHECK:       (type $1 (func))

    ;; CHECK:       (type $sig-2 (sub (func (param eqref (ref $struct)))))

    ;; CHECK:       (type $sig-1 (sub (func (param structref anyref))))
    (type $sig-1 (sub (func (param anyref) (param anyref))))
    (type $sig-2 (sub (func (param anyref) (param anyref))))
  )

  ;; CHECK:      (elem declare func $func-2)

  ;; CHECK:      (func $func-1 (type $sig-1) (param $x structref) (param $y anyref)
  ;; CHECK-NEXT: )
  (func $func-1 (type $sig-1) (param $x anyref) (param $y anyref)
  )

  ;; CHECK:      (func $func-2 (type $sig-2) (param $x eqref) (param $y (ref $struct))
  ;; CHECK-NEXT: )
  (func $func-2 (type $sig-2) (param $x anyref) (param $y anyref)
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (local $any anyref)
  ;; CHECK-NEXT:  (local $struct structref)
  ;; CHECK-NEXT:  (local $i31 i31ref)
  ;; CHECK-NEXT:  (call $func-1
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:   (local.get $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $func-1
  ;; CHECK-NEXT:   (local.get $struct)
  ;; CHECK-NEXT:   (local.get $any)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $func-2
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call_ref $sig-2
  ;; CHECK-NEXT:   (local.get $i31)
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:   (ref.func $func-2)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (local $any (ref null any))
    (local $struct (ref null struct))
    (local $i31 (ref null i31))

    (call $func-1
      (struct.new $struct)
      (local.get $struct)
    )
    (call $func-1
      (local.get $struct)
      (local.get $any)
    )
    (call $func-2
      (struct.new $struct)
      (struct.new $struct)
    )
    (call_ref $sig-2
      (local.get $i31)
      (struct.new $struct)
      (ref.func $func-2)
    )
  )
)

(module
  ;; The presence of a table prevents us from doing any optimizations.

  ;; CHECK:      (type $sig (sub (func (param anyref))))
  (type $sig (sub (func (param anyref))))

  ;; CHECK:      (type $1 (func))

  ;; CHECK:      (type $struct (struct))
  (type $struct (struct))

  (table 1 1 anyref)

  ;; CHECK:      (table $0 1 1 anyref)

  ;; CHECK:      (func $func (type $sig) (param $x anyref)
  ;; CHECK-NEXT: )
  (func $func (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (call $func
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call $func
      (struct.new $struct)
    )
  )
)

(module
  ;; Pass a null in one call to the function. The null can be updated which
  ;; allows us to refine (but the new type must be nullable).

  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $struct (struct))

  ;; CHECK:       (type $1 (func))

  ;; CHECK:       (type $sig (sub (func (param (ref null $struct)))))
  (type $sig (sub (func (param anyref))))

  (type $struct (struct))

  ;; CHECK:      (func $func (type $sig) (param $x (ref null $struct))
  ;; CHECK-NEXT: )
  (func $func (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (call $func
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $func
  ;; CHECK-NEXT:   (ref.null none)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call $func
      (struct.new $struct)
    )
    (call $func
      (ref.null none)
    )
  )
)

(module
  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $0 (func))

    ;; CHECK:       (type $sig-unreachable (sub (func (result anyref))))

    ;; CHECK:       (type $sig-cannot-refine (sub (func (result (ref func)))))

    ;; CHECK:       (type $struct (struct))
    (type $struct (struct))

    ;; This signature has a single function using it, which returns a more
    ;; refined type, and we can refine to that.
    ;; CHECK:       (type $sig-can-refine (sub (func (result (ref $struct)))))
    (type $sig-can-refine (sub (func (result anyref))))

    ;; Also a single function, but no refinement is possible.
    (type $sig-cannot-refine (sub (func (result (ref func)))))

  ;; The single function never returns, so no refinement is possible.
    (type $sig-unreachable (sub (func (result anyref))))
  )

  ;; CHECK:      (elem declare func $func-can-refine $func-cannot-refine)

  ;; CHECK:      (func $func-can-refine (type $sig-can-refine) (result (ref $struct))
  ;; CHECK-NEXT:  (struct.new_default $struct)
  ;; CHECK-NEXT: )
  (func $func-can-refine (type $sig-can-refine) (result anyref)
    (struct.new $struct)
  )

  ;; CHECK:      (func $func-cannot-refine (type $sig-cannot-refine) (result (ref func))
  ;; CHECK-NEXT:  (select (result (ref func))
  ;; CHECK-NEXT:   (ref.func $func-can-refine)
  ;; CHECK-NEXT:   (ref.func $func-cannot-refine)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $func-cannot-refine (type $sig-cannot-refine) (result (ref func))
    (select
      (ref.func $func-can-refine)
      (ref.func $func-cannot-refine)
      (i32.const 0)
    )
  )

  ;; CHECK:      (func $func-unreachable (type $sig-unreachable) (result anyref)
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $func-unreachable (type $sig-unreachable) (result anyref)
    (unreachable)
  )

  ;; CHECK:      (func $caller (type $0)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (if (result (ref $struct))
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (then
  ;; CHECK-NEXT:     (call $func-can-refine)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (else
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (if (result (ref $struct))
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (then
  ;; CHECK-NEXT:     (call_ref $sig-can-refine
  ;; CHECK-NEXT:      (ref.func $func-can-refine)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (else
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    ;; Add a call to see that we update call types properly.
    ;; Put the call in an if so the refinalize will update the if type and get
    ;; printed out conveniently.
    (drop
      (if (result anyref)
        (i32.const 1)
        (then
          (call $func-can-refine)
        )
        (else
          (unreachable)
        )
      )
    )
    ;; The same with a call_ref.
    (drop
      (if (result anyref)
        (i32.const 1)
        (then
          (call_ref $sig-can-refine
            (ref.func $func-can-refine)
          )
        )
        (else
          (unreachable)
        )
      )
    )
  )
)

(module
  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $struct (struct))
  (type $struct (struct))

  ;; This signature has multiple functions using it, and some of them have nulls
  ;; which should be updated when we refine.
  ;; CHECK:       (type $sig (sub (func (result (ref null $struct)))))
  (type $sig (sub (func (result anyref))))

  ;; CHECK:      (func $func-1 (type $sig) (result (ref null $struct))
  ;; CHECK-NEXT:  (struct.new_default $struct)
  ;; CHECK-NEXT: )
  (func $func-1 (type $sig) (result anyref)
    (struct.new $struct)
  )

  ;; CHECK:      (func $func-2 (type $sig) (result (ref null $struct))
  ;; CHECK-NEXT:  (ref.null none)
  ;; CHECK-NEXT: )
  (func $func-2 (type $sig) (result anyref)
    (ref.null any)
  )

  ;; CHECK:      (func $func-3 (type $sig) (result (ref null $struct))
  ;; CHECK-NEXT:  (ref.null none)
  ;; CHECK-NEXT: )
  (func $func-3 (type $sig) (result anyref)
    (ref.null eq)
  )

  ;; CHECK:      (func $func-4 (type $sig) (result (ref null $struct))
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.const 1)
  ;; CHECK-NEXT:   (then
  ;; CHECK-NEXT:    (return
  ;; CHECK-NEXT:     (ref.null none)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $func-4 (type $sig) (result anyref)
    (if
      (i32.const 1)
      (then
        (return
          (ref.null any)
        )
      )
    )
    (unreachable)
  )
)

;; Exports prevent optimization, so $func's type will not change here.
(module
  ;; CHECK:      (type $sig (sub (func (param anyref))))

  ;; CHECK:      (type $1 (func))

  ;; CHECK:      (type $struct (struct))
  (type $struct (struct))

  (type $sig (sub (func (param anyref))))

  ;; CHECK:      (export "prevent-opts" (func $func))

  ;; CHECK:      (func $func (type $sig) (param $x anyref)
  ;; CHECK-NEXT: )
  (func $func (export "prevent-opts") (type $sig) (param $x anyref)
  )

  ;; CHECK:      (func $caller (type $1)
  ;; CHECK-NEXT:  (call $func
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call $func
      (struct.new $struct)
    )
  )
)

(module
  ;; CHECK:      (type $A (sub (func (param i32))))
  (type $A (sub (func (param i32))))
  ;; CHECK:      (type $B (sub $A (func (param i32))))
  (type $B (sub $A (func (param i32))))

  ;; CHECK:      (func $bar (type $B) (param $x i32)
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $bar (type $B) (param $x i32)
   ;; The parameter to this function can be pruned. But while doing so we must
   ;; properly preserve the subtyping of $B from $A, which means we cannot just
   ;; remove it - we'd need to remove it from $A as well, which we don't
   ;; attempt to do in the pass atm. So we do not optimize here.
    (nop)
  )
)

(module
  ;; CHECK:      (type $"{}" (struct))
  (type $"{}" (struct))

  ;; CHECK:      (type $1 (func (param (ref $"{}") i32)))

  ;; CHECK:      (func $foo (type $1) (param $ref (ref $"{}")) (param $i32 i32)
  ;; CHECK-NEXT:  (local $2 eqref)
  ;; CHECK-NEXT:  (local.set $2
  ;; CHECK-NEXT:   (local.get $ref)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (call $foo
  ;; CHECK-NEXT:    (block
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (local.set $2
  ;; CHECK-NEXT:    (ref.null none)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $foo (param $ref eqref) (param $i32 i32)
    (call $foo
      ;; The only reference to the $"{}" type is in this block signature. Even
      ;; this will go away in the internal ReFinalize (which makes the block
      ;; type unreachable).
      (block (result (ref $"{}"))
        (unreachable)
      )
      (i32.const 0)
    )
    ;; Write something of type eqref into $ref. When we refine the type of the
    ;; parameter from eqref to $"{}" we must do something here, as we can no
    ;; longer just write this (ref.null eq) into a parameter of the more
    ;; refined type. While doing so, we must not be confused by the fact that
    ;; the only mention of $"{}" in the original module gets removed during our
    ;; processing, as mentioned in the earlier comment. This is a regression
    ;; test for a crash because of that.
    (local.set $ref
      (ref.null eq)
    )
  )
)

;; Do not modify the types used on imported functions (until the spec and VM
;; support becomes stable).
(module
  ;; CHECK:      (type $0 (func (param structref)))

  ;; CHECK:      (type $1 (func))

  ;; CHECK:      (type $struct (struct))
  (type $struct (struct))

  ;; CHECK:      (import "a" "b" (func $import (type $0) (param structref)))
  (import "a" "b" (func $import (param (ref null struct))))

  ;; CHECK:      (func $test (type $1)
  ;; CHECK-NEXT:  (call $import
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $test
    (call $import
      (struct.new $struct)
    )
  )
)

;; If we refine a type, that may require changes to its subtypes. For now, we
;; skip such optimizations. TODO
(module
  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $A (sub (func (param (ref null $B)) (result (ref null $A)))))
    (type $A (sub (func    (param (ref null $B)) (result (ref null $A)))))
    ;; CHECK:       (type $B (sub $A (func (param (ref null $A)) (result (ref null $B)))))
    (type $B (sub $A (func (param (ref null $A)) (result (ref null $B)))))
  )

  ;; CHECK:      (elem declare func $func)

  ;; CHECK:      (func $func (type $A) (param $0 (ref null $B)) (result (ref null $A))
  ;; CHECK-NEXT:  (ref.func $func)
  ;; CHECK-NEXT: )
  (func $func (type $A) (param $0 (ref null $B)) (result (ref null $A))
    ;; This result is non-nullable, and we could refine type $A accordingly. But
    ;; if we did that, we'd need to refine $B as well.
    (ref.func $func)
  )
)

;; Until we handle contravariance, do not try to optimize a type that has a
;; supertype. In this example, refining the child's anyref to nullref would
;; cause an error.
(module
  ;; CHECK:      (type $parent (sub (func (param anyref))))
  (type $parent (sub (func (param anyref))))
  ;; CHECK:      (type $child (sub $parent (func (param anyref))))
  (type $child (sub $parent (func (param anyref))))

  ;; CHECK:      (type $2 (func))

  ;; CHECK:      (func $func (type $child) (param $0 anyref)
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $func (type $child) (param anyref)
    (unreachable)
  )

  ;; CHECK:      (func $caller (type $2)
  ;; CHECK-NEXT:  (call $func
  ;; CHECK-NEXT:   (ref.null none)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    (call $func
      (ref.null eq)
    )
  )
)

(module
  ;; CHECK:      (type $F (func))
  (type $F (func))

  ;; CHECK:      (func $func (type $F)
  ;; CHECK-NEXT:  (block ;; (replaces unreachable CallRef we can't emit)
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (ref.null nofunc)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (unreachable)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $func
    ;; We should not error on a call_ref to a bottom type.
    (call_ref $F
      (ref.null nofunc)
    )
  )
)

(module
 ;; CHECK:      (rec
 ;; CHECK-NEXT:  (type $0 (func (param (ref $"[i8]"))))

 ;; CHECK:       (type $"[i8]" (array i8))
 (type $"[i8]" (array i8))

 ;; CHECK:       (type $2 (func))

 ;; CHECK:      (func $0 (type $2)
 ;; CHECK-NEXT:  (call $1
 ;; CHECK-NEXT:   (array.new_fixed $"[i8]" 0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $0
  (call $1
   (array.new_fixed $"[i8]" 0)
  )
 )

 ;; CHECK:      (func $1 (type $0) (param $2 (ref $"[i8]"))
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (ref.cast (ref none)
 ;; CHECK-NEXT:    (local.get $2)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $1 (param $2 anyref)
  ;; The param will become non-nullable after we refine. We must refinalize
  ;; after doing so, so the cast becomes non-nullable as well.
  (drop
   (ref.cast structref
    (local.get $2)
   )
  )
 )
)

;; Test the call.without.effects intrinsic, which may require additional work.
(module
 (rec
  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $A (sub (struct)))
  (type $A (sub (struct)))

  ;; CHECK:       (type $B (sub $A (struct)))
  (type $B (sub $A (struct)))

  ;; CHECK:       (type $C (sub $B (struct)))
  (type $C (sub $B (struct)))

  ;; CHECK:       (type $return_A_2 (func (result (ref $C))))

  ;; CHECK:       (type $return_A (func (result (ref $B))))
  (type $return_A (func (result (ref null $A))))

  (type $return_A_2 (func (result (ref null $A))))
 )

 ;; CHECK:       (type $5 (func))

 ;; CHECK:       (type $6 (func (param funcref) (result (ref null $A))))

 ;; CHECK:      (type $7 (func (param funcref) (result (ref $B))))

 ;; CHECK:      (type $8 (func (param funcref) (result (ref $C))))

 ;; CHECK:      (import "binaryen-intrinsics" "call.without.effects" (func $no.side.effects (type $6) (param funcref) (result (ref null $A))))
 (import "binaryen-intrinsics" "call.without.effects" (func $no.side.effects
   (param funcref)
   (result (ref null $A))
 ))

 ;; CHECK:      (import "binaryen-intrinsics" "call.without.effects" (func $no.side.effects_4 (type $7) (param funcref) (result (ref $B))))

 ;; CHECK:      (import "binaryen-intrinsics" "call.without.effects" (func $no.side.effects_5 (type $8) (param funcref) (result (ref $C))))

 ;; CHECK:      (elem declare func $other $other2)

 ;; CHECK:      (func $func (type $5)
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (call $no.side.effects_4
 ;; CHECK-NEXT:    (ref.func $other)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (call $no.side.effects_4
 ;; CHECK-NEXT:    (ref.func $other)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (call $no.side.effects_5
 ;; CHECK-NEXT:    (ref.func $other2)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $func
  ;; After $other's result is refined, this will need to use a new import that
  ;; has the refined result type.
  (drop
   (call $no.side.effects
    (ref.func $other)
   )
  )
  ;; A second call of the same one. This should call the same new import (that
  ;; is, we shouldn't create unnecessary copies of the new imports).
  (drop
   (call $no.side.effects
    (ref.func $other)
   )
  )
  ;; A call of another function with a different refining, that will need
  ;; another import.
  (drop
   (call $no.side.effects
    (ref.func $other2)
   )
  )
 )

 ;; CHECK:      (func $other (type $return_A) (result (ref $B))
 ;; CHECK-NEXT:  (struct.new_default $B)
 ;; CHECK-NEXT: )
 (func $other (type $return_A) (result (ref null $A))
  (struct.new $B) ;; this will allow this function's result to be refined to $B
 )

 ;; CHECK:      (func $other2 (type $return_A_2) (result (ref $C))
 ;; CHECK-NEXT:  (struct.new_default $C)
 ;; CHECK-NEXT: )
 (func $other2 (type $return_A_2) (result (ref null $A))
  (struct.new $C) ;; this will allow this function's result to be refined to $C
 )
)

;; Test we consider call.without.effects when deciding what to refine. $A has
;; two subtypes, B1 and B2, and a call.without.effects sends in one while a
;; normal call sends in the other. As a result, we cannot refine the parameter
;; at all.
(module
 (rec
  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $A (sub (struct)))
  (type $A (sub (struct)))

  ;; CHECK:       (type $B1 (sub $A (struct)))
  (type $B1 (sub $A (struct)))

  ;; CHECK:       (type $B2 (sub $A (struct)))
  (type $B2 (sub $A (struct)))
 )

 ;; CHECK:      (type $3 (func (param (ref $A) funcref)))

 ;; CHECK:      (type $4 (func))

 ;; CHECK:      (type $5 (func (param (ref $A))))

 ;; CHECK:      (import "binaryen-intrinsics" "call.without.effects" (func $no.side.effects (type $3) (param (ref $A) funcref)))
 (import "binaryen-intrinsics" "call.without.effects" (func $no.side.effects
   (param (ref $A))
   (param funcref)
 ))

 ;; CHECK:      (elem declare func $target)

 ;; CHECK:      (func $calls (type $4)
 ;; CHECK-NEXT:  (call $no.side.effects
 ;; CHECK-NEXT:   (struct.new_default $B1)
 ;; CHECK-NEXT:   (ref.func $target)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (call $target
 ;; CHECK-NEXT:   (struct.new_default $B2)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $calls
  (call $no.side.effects
   (struct.new $B1)
   (ref.func $target)
  )
  (call $target
   (struct.new $B2)
  )
 )

 ;; CHECK:      (func $target (type $5) (param $x (ref $A))
 ;; CHECK-NEXT: )
 (func $target (param $x (ref $A))
  ;; Because of the two calls above, this cannot be refined.
 )
)

;; As above, but now we can refine the parameter to the called function.
(module
 (rec
  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $A (sub (struct)))
  (type $A (sub (struct)))

  ;; CHECK:       (type $1 (func (param (ref $B))))

  ;; CHECK:       (type $B (sub $A (struct)))
  (type $B (sub $A (struct)))
 )

 ;; CHECK:       (type $3 (func))

 ;; CHECK:       (type $4 (func (param (ref $A) funcref)))

 ;; CHECK:      (import "binaryen-intrinsics" "call.without.effects" (func $no.side.effects (type $4) (param (ref $A) funcref)))
 (import "binaryen-intrinsics" "call.without.effects" (func $no.side.effects
   (param (ref $A))
   (param funcref)
 ))

 ;; CHECK:      (elem declare func $target)

 ;; CHECK:      (func $calls (type $3)
 ;; CHECK-NEXT:  (call $no.side.effects
 ;; CHECK-NEXT:   (struct.new_default $B)
 ;; CHECK-NEXT:   (ref.func $target)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (call $target
 ;; CHECK-NEXT:   (struct.new_default $B)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $calls
  (call $no.side.effects
   (struct.new $B)        ;; this changed to $B
   (ref.func $target)
  )
  (call $target
   (struct.new $B)        ;; this also changed to $B
  )
 )

 ;; CHECK:      (func $target (type $1) (param $x (ref $B))
 ;; CHECK-NEXT: )
 (func $target (param $x (ref $A))
  ;; The two calls above both send $B, so we can refine the parameter to $B.
  ;;
  ;; Note that the signature of the import $no.side.effects does *not* change;
  ;; the refined values sent are valid to send to the old parameter types there
  ;; (see tests above for how we handle refining of return values).
 )
)

;; Visibility: The type we'd like to refine, $sig, is in a rec group with a
;; public type, so do not optimize.
(module
 (rec
  ;; CHECK:      (rec
  ;; CHECK-NEXT:  (type $sig (sub (func (param anyref))))
  (type $sig (sub (func (param anyref))))

  ;; CHECK:       (type $struct (struct))
  (type $struct (struct))
 )

 ;; Export a global with $struct to make it public.
 ;; CHECK:      (type $2 (func))

 ;; CHECK:      (global $struct (ref $struct) (struct.new_default $struct))
 (global $struct (ref $struct) (struct.new $struct))

 ;; CHECK:      (export "struct" (global $struct))
 (export "struct" (global $struct))

 ;; CHECK:      (func $func (type $sig) (param $x anyref)
 ;; CHECK-NEXT: )
 (func $func (type $sig) (param $x anyref))

 ;; CHECK:      (func $caller (type $2)
 ;; CHECK-NEXT:  (call $func
 ;; CHECK-NEXT:   (struct.new_default $struct)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $caller
  (call $func
   (struct.new $struct)
  )
 )
)

;; Tags: The type we'd like to refine, $sig, is used by a tag, so do not
;; optimize.
(module
  ;; CHECK:      (type $sig (func (param anyref)))
  (type $sig (func (param anyref)))

  ;; CHECK:      (type $1 (func))

  ;; CHECK:      (tag $e (type $sig) (param anyref))
  (tag $e (type $sig))

  ;; CHECK:      (func $optimizable (type $sig) (param $0 anyref)
  ;; CHECK-NEXT:  (call $optimizable
  ;; CHECK-NEXT:   (ref.cast eqref
  ;; CHECK-NEXT:    (local.get $0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $optimizable (type $sig) (param anyref)
    (call $optimizable
      (ref.cast eqref
        (local.get 0)
      )
    )
  )

  ;; CHECK:      (func $throw (type $1)
  ;; CHECK-NEXT:  (local $0 anyref)
  ;; CHECK-NEXT:  (throw $e
  ;; CHECK-NEXT:   (local.get $0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $throw
    (local anyref)
    ;; This would be invalid if we optimized $sig.
    (throw $e
      (local.get 0)
    )
  )
)
