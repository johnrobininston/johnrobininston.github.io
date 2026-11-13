"""Generate the project's reproducible Monte Carlo pricing illustration.

Run from the repository root:
    .venv/bin/python projects/bs-option-pricing/pricing_visualization.py
"""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from scipy.stats import norm


def simulate_pricing(seed=7, n_paths=100_000, n_steps=126):
    """Exact GBM transitions under Q, with online payoff moments."""
    spot, strike, maturity, rate, volatility = 100., 105., .5, .04, .2
    dt = maturity / n_steps
    rng = np.random.default_rng(seed)
    stock = np.full(n_paths, spot)
    # Keep a representative subset for display, but price using every path.
    paths = np.empty((n_steps + 1, 32))
    paths[0] = spot
    for step in range(n_steps):
        stock *= np.exp((rate - .5 * volatility**2) * dt
                        + volatility * np.sqrt(dt)
                        * rng.standard_normal(n_paths))
        paths[step + 1] = stock[:32]
    payoff = np.exp(-rate * maturity) * np.maximum(stock - strike, 0)
    count = np.arange(1, n_paths + 1)
    mean = np.cumsum(payoff) / count
    # Welford's recurrence avoids cancellation in the running variance.
    increments = payoff - np.r_[0., mean[:-1]]
    m2 = np.cumsum(increments * (payoff - mean))
    se = np.full(n_paths, np.nan)
    se[1:] = np.sqrt(np.maximum(m2[1:], 0) / (count[1:] - 1) / count[1:])
    dp = (np.log(spot / strike) + (rate + .5 * volatility**2)
          * maturity) / (volatility * np.sqrt(maturity))
    dm = dp - volatility * np.sqrt(maturity)
    exact = spot * norm.cdf(dp) - strike * np.exp(-rate * maturity) * norm.cdf(dm)
    return dict(paths=paths, count=count, mean=mean, se=se, exact=exact,
                payoff=payoff, maturity=maturity, strike=strike)


def make_figure(output=None):
    data = simulate_pricing()
    # Match _extensions/cadojo/catppuccin/frappe.scss.
    bg, ink, muted = "#303446", "#c6d0f5", "#a5adce"
    blue, orange = "#8caaee", "#ef9f76"
    plt.rcParams.update({
        "font.family": "DejaVu Sans", "font.size": 11,
        "text.color": ink, "axes.titlecolor": ink,
        "axes.labelcolor": ink, "legend.labelcolor": ink,
    })
    fig, (left, right) = plt.subplots(1, 2, figsize=(12, 6.2))
    fig.set_facecolor(bg)
    fig.subplots_adjust(left=.075, right=.97, bottom=.23, top=.71, wspace=.28)
    fig.text(.075, .91, "From stock paths to an option price", color=ink,
             fontsize=23, weight="bold")
    fig.text(.075, .845, "Risk-neutral simulation  /  European call",
             color=muted, fontsize=13)
    fig.text(.075, .79,
             r"$S_0=100$     $K=105$     $T=0.5$ years     $r=4\%$"
             r"     $\sigma=20\%$     $q=0$", color=muted, fontsize=11)
    for ax in (left, right):
        ax.set_facecolor(bg)
        ax.spines[["top", "right"]].set_visible(False)
        ax.spines[["left", "bottom"]].set_color("#626880")
        ax.tick_params(colors=muted, which="both")
        ax.grid(axis="y", color="#414559", linewidth=.7)
        ax.set_axisbelow(True)
        ax.xaxis.label.set_color(ink)
        ax.yaxis.label.set_color(ink)
    times = np.linspace(0, data["maturity"], len(data["paths"]))
    left.plot(times, data["paths"], color=blue, alpha=.35, lw=1)
    left.axhline(data["strike"], color=orange, ls="--", lw=1.5,
                 label="Strike = 105")
    left.set(title="1. Simulate stock prices under Q",
             xlabel="Time (years)", ylabel="Stock price")
    left.legend(frameon=False, loc="upper left", fontsize=10)
    # Show log-spaced sample counts without drawing 100,000 points.
    ix = np.unique(np.geomspace(100, len(data["count"]), 450).astype(int)) - 1
    n, mean, se = (data[key][ix] for key in ("count", "mean", "se"))
    right.fill_between(n, mean - 1.96 * se, mean + 1.96 * se,
                       color=blue, alpha=.20, label="Pointwise 95% interval")
    right.plot(n, mean, color=blue, lw=1.8, label="Discounted average payoff")
    right.axhline(data["exact"], color=orange, ls="--", lw=1.8,
                  label=f"Black-Scholes = {data['exact']:.3f}")
    right.set(xscale="log", title="2. Average the discounted payoffs",
              xlabel="Number of simulated paths", ylabel="Call price")
    right.legend(frameon=False, fontsize=9, loc="upper right")
    mean, se = data["mean"][-1], data["se"][-1]
    fig.text(.075, .105,
             f"100,000 paths:  Monte Carlo {mean:.3f}  |  "
             f"Black-Scholes {data['exact']:.3f}  |  "
             f"standard error {se:.3f}", fontsize=12, color=ink)
    fig.text(.075, .055,
             r"Price estimate = $e^{-rT}\,\frac{1}{N}"
             r"\sum_{i=1}^{N}\max(S_T^{(i)}-K,0)$"
             "     |     Simulated data, fixed seed", fontsize=11, color=muted)
    output = Path(output) if output else (
        Path(__file__).with_name("pricing-simulation.png")
    )
    fig.savefig(output, dpi=180, facecolor=bg)
    plt.close(fig)
    print(f"Saved {output.name}: MC={mean:.6f}, "
          f"BS={data['exact']:.6f}, SE={se:.6f}")
    return data


if __name__ == "__main__":
    make_figure()
