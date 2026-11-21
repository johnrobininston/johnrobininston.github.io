"""Draw the toy pywr network from the model's own graph."""
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch
from toy_model import model

BG, TXT = "#303446", "#c6d0f5"
COL = {"Input": "#8caaee", "Storage": "#ef9f76",
       "Output": "#a6d189", "Link": "#e5c890"}
pos = {"river": (0, 1), "reservoir": (3, 1), "urban": (6, 2),
       "ag": (6, 1), "spill": (6, 0)}

fig, ax = plt.subplots(figsize=(9, 4))
fig.patch.set_facecolor(BG)
ax.set_facecolor(BG)
ax.set_xlim(-1, 7.2)
ax.set_ylim(-0.8, 2.8)
ax.axis("off")

def top(n):
    # storage is split into hidden input/output sub-nodes in the graph
    return getattr(n, "parent", None) or n


for a, b in model.graph.edges():
    a, b = top(a), top(b)
    rad = 0.0
    if (a.name, b.name) == ("river", "spill"):
        rad = 0.35
    ax.add_patch(FancyArrowPatch(
        pos[a.name], pos[b.name], connectionstyle=f"arc3,rad={rad}",
        arrowstyle="-|>", mutation_scale=15, color=TXT, lw=1.3,
        shrinkA=28, shrinkB=28))

for n in model.nodes:
    x, y = pos[n.name]
    ax.add_patch(FancyBboxPatch((x - 0.5, y - 0.25), 1, 0.5,
                 boxstyle="round,pad=0.02", fc=COL[type(n).__name__],
                 ec="none", zorder=3))
    cost = getattr(n, "cost", None)
    lab = f"{n.name}\n{type(n).__name__}"
    ax.text(x, y, lab, ha="center", va="center", color=BG, fontsize=9,
            zorder=4, fontweight="bold")
    if n.name in ("urban", "ag", "spill"):
        ax.text(x + 0.6, y, f"cost {cost}", va="center", color=TXT,
                fontsize=8)
ax.text(0, 0.45, "max_flow = daily inflow\ncost -10", ha="center",
        color=TXT, fontsize=8)
ax.text(3, 0.45, "max 5000, start 2500", ha="center", color=TXT,
        fontsize=8)
plt.savefig("network.png", dpi=150, facecolor=BG, bbox_inches="tight")
