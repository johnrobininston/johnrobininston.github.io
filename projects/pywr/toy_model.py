"""
title: Toy pywr network
author: John Inston
date: 2026-11-15
"""

# INFORMATION:
# River Inflow -> Reservoir -> Urban + Ag Demand

# Packages
from pywr.recorders import NumpyArrayStorageRecorder, NumpyArrayNodeRecorder
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pywr.model import Model
from pywr.nodes import Input, Storage, Output, Link
from pywr.parameters import DataFrameParameter

# Random seed
rng = np.random.default_rng(0)

# Days
days = pd.date_range("2000-01-01", "2009-12-31", freq="D")
doy = days.dayofyear.values

# Seasonal snowmelt-like inflow (Ml/day) with lognormal noise
inflow = 40 * (1 + 0.9 * np.sin(2 * np.pi * (doy - 90) / 365)) * \
    rng.lognormal(0, 0.3, len(days))
inflow_df = pd.DataFrame({"inflow": inflow}, index=days)

model = Model(start=days[0], end=days[-1], timestep=1)

river = Input(model, "river")
river.max_flow = DataFrameParameter(model, inflow_df["inflow"])
river.cost = -10

res = Storage(model, "reservoir", max_volume=5000, initial_volume=2500,
              inputs=1, outputs=1)
river.connect(res)

urban = Output(model, "urban", max_flow=12, cost=-100)
ag = Output(model, "ag", max_flow=22, cost=-50)
spill = Output(model, "spill", cost=1000)
res.connect(urban)
res.connect(ag)
res.connect(spill)
river.connect(spill)

sto = NumpyArrayStorageRecorder(model, res)
u = NumpyArrayNodeRecorder(model, urban)
a = NumpyArrayNodeRecorder(model, ag)

if __name__ == "__main__":
    model.run()
    out = pd.DataFrame({"storage": sto.data[:, 0], "urban": u.data[:, 0],
                        "ag": a.data[:, 0]}, index=days)
    print(out.describe().round(1))
    print("urban shortfall days:", int((out.urban < 12 - 1e-6).sum()))
    print("ag shortfall days:", int((out.ag < 22 - 1e-6).sum()))
    fig, ax = plt.subplots(2, 1, figsize=(9, 5), sharex=True)
    out.storage.plot(ax=ax[0], title="Reservoir storage")
    out[["urban", "ag"]].resample("MS").mean().plot(ax=ax[1],
                                                    title="Monthly supply")
    plt.tight_layout()
    plt.savefig("toy_model.png", dpi=150)
