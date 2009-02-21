(* Copyright (c) 2008, Adam Chlipala
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * - The names of contributors may not be used to endorse or promote products
 *   derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *)

structure ElabOps :> ELAB_OPS = struct

open Elab

structure E = ElabEnv
structure U = ElabUtil

fun liftConInCon by =
    U.Con.mapB {kind = fn k => k,
                con = fn bound => fn c =>
                                     case c of
                                         CRel xn =>
                                         if xn < bound then
                                             c
                                         else
                                             CRel (xn + by)
                                       (*| CUnif _ => raise SynUnif*)
                                       | _ => c,
                bind = fn (bound, U.Con.Rel _) => bound + 1
                        | (bound, _) => bound}

fun subConInCon' rep =
    U.Con.mapB {kind = fn k => k,
                con = fn (by, xn) => fn c =>
                                        case c of
                                            CRel xn' =>
                                            (case Int.compare (xn', xn) of
                                                 EQUAL => #1 (liftConInCon by 0 rep)
                                               | GREATER => CRel (xn' - 1)
                                               | LESS => c)
                                          (*| CUnif _ => raise SynUnif*)
                                          | _ => c,
                bind = fn ((by, xn), U.Con.Rel _) => (by+1, xn+1)
                        | (ctx, _) => ctx}

val liftConInCon = liftConInCon 1

fun subConInCon (xn, rep) = subConInCon' rep (0, xn)

fun subStrInSgn (m1, m2) =
    U.Sgn.map {kind = fn k => k,
               con = fn c as CModProj (m1', ms, x) =>
                        if m1 = m1' then
                            CModProj (m2, ms, x)
                        else
                            c
                      | c => c,
               sgn_item = fn sgi => sgi,
               sgn = fn sgn => sgn}


fun hnormCon env (cAll as (c, loc)) =
    case c of
        CUnif (_, _, _, ref (SOME c)) => hnormCon env c

      | CNamed xn =>
        (case E.lookupCNamed env xn of
             (_, _, SOME c') => hnormCon env c'
           | _ => cAll)

      | CModProj (n, ms, x) =>
        let
            val (_, sgn) = E.lookupStrNamed env n
            val (str, sgn) = foldl (fn (m, (str, sgn)) =>
                                       case E.projectStr env {sgn = sgn, str = str, field = m} of
                                           NONE => raise Fail "hnormCon: Unknown substructure"
                                         | SOME sgn => ((StrProj (str, m), loc), sgn))
                             ((StrVar n, loc), sgn) ms
        in
            case E.projectCon env {sgn = sgn, str = str, field = x} of
                NONE => raise Fail "kindof: Unknown con in structure"
              | SOME (_, NONE) => cAll
              | SOME (_, SOME c) => hnormCon env c
        end

      | CApp (c1, c2) =>
        (case #1 (hnormCon env c1) of
             CAbs (x, k, cb) =>
             let
                 val sc = (hnormCon env (subConInCon (0, c2) cb))
                     handle SynUnif => cAll
                 (*val env' = E.pushCRel env x k*)
             in
                 (*Print.eprefaces "Subst" [("x", Print.PD.string x),
                                          ("cb", ElabPrint.p_con env' cb),
                                          ("c2", ElabPrint.p_con env c2),
                                          ("sc", ElabPrint.p_con env sc)];*)
                 sc
             end
           | c1' as CApp (c', f) =>
             let
                 fun default () = (CApp ((c1', loc), hnormCon env c2), loc)
             in
                 case #1 (hnormCon env c') of
                     CMap (ks as (k1, k2)) =>
                     (case #1 (hnormCon env c2) of
                          CRecord (_, []) => (CRecord (k2, []), loc)
                        | CRecord (_, (x, c) :: rest) =>
                          hnormCon env
                                   (CConcat ((CRecord (k2, [(x, (CApp (f, c), loc))]), loc),
                                             (CApp (c1, (CRecord (k2, rest), loc)), loc)), loc)
                        | CConcat ((CRecord (k, (x, c) :: rest), _), rest') =>
                          let
                              val rest'' = (CConcat ((CRecord (k, rest), loc), rest'), loc)
                          in
                              hnormCon env
                                       (CConcat ((CRecord (k2, [(x, (CApp (f, c), loc))]), loc),
                                                 (CApp (c1, rest''), loc)), loc)
                          end
                        | _ =>
                          let
                              fun unconstraint c =
                                  case hnormCon env c of
                                      (CDisjoint (_, _, _, c), _) => unconstraint c
                                    | c => c

                              fun tryDistributivity () =
                                  case hnormCon env c2 of
                                      (CConcat (c1, c2'), _) =>
                                      let
                                          val c = (CMap ks, loc)
                                          val c = (CApp (c, f), loc)
                                                  
                                          val c1 = (CApp (c, c1), loc)
                                          val c2 = (CApp (c, c2'), loc)
                                          val c = (CConcat (c1, c2), loc)
                                      in
                                          hnormCon env c
                                      end
                                    | _ => default ()

                              fun tryFusion () =
                                  case #1 (hnormCon env c2) of
                                      CApp (f', r') =>
                                      (case #1 (hnormCon env f') of
                                           CApp (f', inner_f) =>
                                           (case #1 (hnormCon env f') of
                                                CMap (dom, _) =>
                                                let
                                                    val f' = (CApp (inner_f, (CRel 0, loc)), loc)
                                                    val f' = (CApp (f, f'), loc)
                                                    val f' = (CAbs ("v", dom, f'), loc)

                                                    val c = (CMap (dom, k2), loc)
                                                    val c = (CApp (c, f'), loc)
                                                    val c = (CApp (c, r'), loc)
                                                in
                                                    hnormCon env c
                                                end
                                              | _ => tryDistributivity ())
                                         | _ => tryDistributivity ())
                                    | _ => tryDistributivity ()

                              fun tryIdentity () =
                                  let
                                      fun cunif () =
                                          let
                                              val r = ref NONE
                                          in
                                              (r, (CUnif (loc, (KType, loc), "_", r), loc))
                                          end
                                          
                                      val (vR, v) = cunif ()

                                      val c = (CApp (f, v), loc)
                                  in
                                      case unconstraint c of
                                          (CUnif (_, _, _, vR'), _) =>
                                          if vR' = vR then
                                              hnormCon env c2
                                          else
                                              tryFusion ()
                                        | _ => tryFusion ()
                                  end
                          in
                              tryIdentity ()
                          end)
                   | _ => default ()
             end
           | c1' => (CApp ((c1', loc), hnormCon env c2), loc))
        
      | CConcat (c1, c2) =>
        (case (hnormCon env c1, hnormCon env c2) of
             ((CRecord (k, xcs1), loc), (CRecord (_, xcs2), _)) =>
             (CRecord (k, xcs1 @ xcs2), loc)
           | ((CRecord (_, []), _), c2') => c2'
           | ((CConcat (c11, c12), loc), c2') =>
             hnormCon env (CConcat (c11, (CConcat (c12, c2'), loc)), loc)
           | (c1', (CRecord (_, []), _)) => c1'
           | (c1', c2') => (CConcat (c1', c2'), loc))

      | CProj (c, n) =>
        (case hnormCon env c of
             (CTuple cs, _) => hnormCon env (List.nth (cs, n - 1))
           | _ => cAll)

      | _ => cAll

end
