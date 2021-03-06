open Tree;;
open Printf;;
open Str;;
open List;;
open Hashtbl;;
open Buffer;;
open Utils;;

let get_ax t = match t with
	| Binop(Impl, a, Binop(Impl, b, a1)) when a = a1 -> 1
	| Binop(Impl, Binop(Impl, a, b), Binop(Impl, Binop(Impl, a2, Binop(Impl, b1, c1)), Binop(Impl, a1, c))) when a = a1 && a1 = a2 && b = b1 && c = c1 -> 2
	| Binop(Impl, a, Binop(Impl, b, Binop(Conj, a1, b1))) when a = a1 && b = b1 -> 3
	| Binop(Impl, Binop(Conj, a, b), a1) when a = a1 -> 4
	| Binop(Impl, Binop(Conj, a, b), b1) when b = b1 -> 5
	| Binop(Impl, a, Binop(Disj, a1, b)) when a = a1 -> 6
	| Binop(Impl, b, Binop(Disj, a, b1)) when b = b1 -> 7
	| Binop(Impl, Binop(Impl, a, c), Binop(Impl, Binop(Impl, b, c1), Binop(Impl, Binop(Disj, a1, b1), c2))) when a = a1 && b = b1 && c = c1 && c1 = c2 -> 8
	| Binop(Impl, Binop(Impl, a, b), Binop(Impl, Binop(Impl, a1, Neg(b1)), Neg(a2))) when a = a1 && a1 = a2 && b = b1 -> 9
	| Binop(Impl, Neg(Neg(a)), a1) when a = a1 -> 10
	| _ -> 0
;;

let get_hpt t hpts = 
	if mem hpts t = true then find hpts t
	else 0
;;

let upd_mp t n proved_mp impls exps =
	(*1st case - impl, exp*)
	let proving = Hashtbl.find_all impls t in
	List.iter (fun (tree, idx) -> add proved_mp tree (idx, n)) proving;
	let rm_all h x = 
		while Hashtbl.mem h x = true
		do
			Hashtbl.remove h x
		done
	in
	rm_all impls t;
	begin
		match t with
		| Binop(Impl, a, b) -> 
			add impls a (b, n);
			(*2nd case - exp, impl*)
			if mem exps a = true then 
				begin 
				add proved_mp b (n, find exps a) 
				end
		| _ -> ()
	end;
	add exps t n
;;
	
let get_mp t proved_mp =
	if mem proved_mp t = true then find proved_mp t
	else (0, 0)
;;

let annotate s n proved_mp impls exps hpts = 
	let tree = string_to_tree s in
	let hyp = get_hpt tree hpts in
	let ax = get_ax tree in
	let mp = get_mp tree proved_mp in
	let i = fst mp in
	let j = snd mp in
	let buf = Buffer.create 100 in
		add_string buf s;
		if hyp > 0 then 
			begin
			add_string buf "#0 "; add_string buf (string_of_int (hyp - 1))
			end
		else if ax > 0 then
			begin
			add_string buf "#1 "; add_string buf (string_of_int (ax - 1))
			end
		else if i > 0 && j > 0 then
			begin
			add_string buf "#2 "; add_string buf (string_of_int (i - 1)); add_string buf " "; add_string buf (string_of_int (j - 1))
			end
		else begin
			add_string buf " (Не доказано)"; print_endline "!you have a bug!\n" end
		;
		upd_mp tree n proved_mp impls exps;
		contents buf
;;