from device import build_cgra
from checker import check_mapping

G = build_cgra(5, 5)
N = G["names"]          # name -> vertex id


def ids(*names):
    return {N[n] for n in names}


def make_dfg(kinds, edges):
    succ = [[] for _ in kinds]
    pred = [[] for _ in kinds]
    for a, b in edges:
        succ[a].append(b)
        pred[b].append(a)
    return dict(kind=kinds, succ=succ, pred=pred)


# DFG: node 0 = input (io), node 1 = op (alu), node 2 = output (io)
H = make_dfg(["io", "alu", "io"], [(0, 1), (1, 2)])


def good_phi():
    return [ids("io_0_0", "out_0_0"),
            ids("alu_0_4", "out_0_4"),
            ids("io_0_4")]


results = []


def expect(label, ok_wanted, ok, reason, must_contain=""):
    passed = (ok == ok_wanted) and (must_contain in reason)
    results.append(passed)
    print(f"{'PASS' if passed else 'FAIL'}  {label:<44} -> {reason}")


# ---- must pass ----
ok, why = check_mapping(H, G, good_phi())
expect("legal mapping accepted", True, ok, why)

# ---- must fail, one at a time ----
phi = good_phi(); phi[1] |= ids("out_0_0")
ok, why = check_mapping(H, G, phi)
expect("overlap (out_0_0 in two models)", False, ok, why, "rule 1")

phi = good_phi(); phi[1] = ids("out_0_3", "out_0_4")
ok, why = check_mapping(H, G, phi)
expect("no compute vertex in op's model", False, ok, why, "rule 2")

phi = good_phi(); phi[1] |= ids("out_2_2")
ok, why = check_mapping(H, G, phi)
expect("disconnected model (out_2_2 far away)", False, ok, why, "rule 3")

phi = good_phi(); phi[1] = ids("alu_2_2", "out_2_2")
ok, why = check_mapping(H, G, phi)
expect("op placed far from its input (no adjacency)", False, ok, why, "rule 4")

# direction test: add z (alu) with edges op->z and z->op
Hz = make_dfg(["io", "alu", "io", "alu"], [(0, 1), (1, 2), (1, 3), (3, 1)])
phi = good_phi() + [ids("alu_0_3")]
ok, why = check_mapping(Hz, G, phi)
expect("direction: op->z fine, z->op impossible", False, ok, why, "rule 4: DFG edge 3->1")

print()
print(f"{sum(results)}/{len(results)} tests behaved as expected")