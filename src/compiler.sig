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

(* Ur/Web main compiler interface *)

signature COMPILER = sig

    type job = {
         prefix : string,
         database : string option,
         sources : string list,
         exe : string,
         sql : string option,
         debug : bool,
         profile : bool
    }
    val compile : string -> unit
    val compileC : {cname : string, oname : string, ename : string, libs : string, profile : bool} -> unit

    type ('src, 'dst) phase
    type ('src, 'dst) transform

    val transform : ('src, 'dst) phase -> string -> ('src, 'dst) transform
    val o : ('b, 'c) transform * ('a, 'b) transform -> ('a, 'c) transform

    val check : ('src, 'dst) transform -> 'src -> unit
    val run : ('src, 'dst) transform -> 'src -> 'dst option
    val runPrint : ('src, 'dst) transform -> 'src -> unit
    val time : ('src, 'dst) transform -> 'src -> unit
    val timePrint : ('src, 'dst) transform -> 'src -> unit

    val parseUr : (string, Source.file) phase
    val parseUrs : (string, Source.sgn_item list) phase
    val parseUrp : (string, job) phase

    val parse : (job, Source.file) phase
    val elaborate : (Source.file, Elab.file) phase
    val unnest : (Elab.file, Elab.file) phase
    val termination : (Elab.file, Elab.file) phase
    val explify : (Elab.file, Expl.file) phase
    val corify : (Expl.file, Core.file) phase
    val especialize : (Core.file, Core.file) phase
    val core_untangle : (Core.file, Core.file) phase
    val shake : (Core.file, Core.file) phase
    val rpcify : (Core.file, Core.file) phase
    val tag : (Core.file, Core.file) phase
    val reduce : (Core.file, Core.file) phase
    val unpoly : (Core.file, Core.file) phase
    val specialize : (Core.file, Core.file) phase
    val monoize : (Core.file, Mono.file) phase
    val mono_opt : (Mono.file, Mono.file) phase
    val untangle : (Mono.file, Mono.file) phase
    val mono_reduce : (Mono.file, Mono.file) phase
    val mono_shake : (Mono.file, Mono.file) phase
    val jscomp : (Mono.file, Mono.file) phase
    val fuse : (Mono.file, Mono.file) phase
    val pathcheck : (Mono.file, Mono.file) phase
    val cjrize : (Mono.file, Cjr.file) phase
    val prepare : (Cjr.file, Cjr.file) phase
    val sqlify : (Mono.file, Cjr.file) phase

    val toParseJob : (string, job) transform
    val toParse : (string, Source.file) transform
    val toElaborate : (string, Elab.file) transform
    val toUnnest : (string, Elab.file) transform
    val toTermination : (string, Elab.file) transform
    val toExplify : (string, Expl.file) transform
    val toCorify : (string, Core.file) transform
    val toEspecialize : (string, Core.file) transform 
    val toCore_untangle : (string, Core.file) transform
    val toShake1 : (string, Core.file) transform
    val toRpcify : (string, Core.file) transform
    val toCore_untangle2 : (string, Core.file) transform
    val toShake2 : (string, Core.file) transform
    val toTag : (string, Core.file) transform
    val toReduce : (string, Core.file) transform
    val toUnpoly : (string, Core.file) transform 
    val toSpecialize : (string, Core.file) transform 
    val toShake3 : (string, Core.file) transform
    val toMonoize : (string, Mono.file) transform
    val toMono_opt1 : (string, Mono.file) transform
    val toUntangle : (string, Mono.file) transform
    val toMono_reduce : (string, Mono.file) transform
    val toMono_shake : (string, Mono.file) transform
    val toMono_opt2 : (string, Mono.file) transform
    val toJscomp : (string, Mono.file) transform
    val toMono_opt3 : (string, Mono.file) transform
    val toFuse : (string, Mono.file) transform
    val toUntangle2 : (string, Mono.file) transform
    val toMono_reduce2 : (string, Mono.file) transform
    val toMono_shake2 : (string, Mono.file) transform
    val toPathcheck : (string, Mono.file) transform
    val toCjrize : (string, Cjr.file) transform
    val toPrepare : (string, Cjr.file) transform
    val toSqlify : (string, Cjr.file) transform

end
