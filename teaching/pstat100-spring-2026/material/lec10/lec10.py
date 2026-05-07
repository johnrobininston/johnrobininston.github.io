"""
title: Lecture 10 - SLR
author: John Inston
date: 2026-04-26
"""

# Libraries
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.datasets import load_diabetes
import statsmodels.formula.api as smf

# Load the diabetes dataset
diabetes_sklearn = load_diabetes()

# Convert the dataset to a DataFrame
diabetes_df = pd.DataFrame(data=diabetes_sklearn.data,
                           columns=diabetes_sklearn.feature_names)

# Add target variable to the DataFrame
diabetes_df['progression'] = diabetes_sklearn.target

# EDA for SlR
diabetes_df.corr()

df_slr = diabetes_df[['bmi', 'progression']]

# EDA for SLR
sns.scatterplot(x='bmi', y='progression', data=df_slr, alpha=0.5)
plt.title('Scatter Plot of BMI vs. Disease Progression')
plt.xlabel('BMI')
plt.ylabel('Disease Progression')
plt.show()

# SLR
model_slr = smf.ols(formula='progression ~ bmi', data=diabetes_df).fit()

# Print the summary of the SLR model
print(model_slr.summary())

# Build a prediction grid
x_grid = pd.DataFrame({
    'bmi': np.linspace(
        df_slr['bmi'].min(),
        df_slr['bmi'].max(), 200)
})

# Get predictions with confidence interval
pred_ci = model_slr.get_prediction(x_grid).summary_frame(alpha=0.05)

fig, ax = plt.subplots(figsize=(10, 6))
ax.scatter(df_slr['bmi'], df_slr['progression'],
           alpha=0.4, color='steelblue', s=35, label='Observed data', zorder=3)
ax.plot(x_grid['bmi'], pred_ci['mean'],
        color='crimson', lw=2.5, label='OLS fit')
ax.fill_between(x_grid['bmi'],
                pred_ci['mean_ci_lower'], pred_ci['mean_ci_upper'],
                alpha=0.25, color='crimson', label='95% CI for mean')
ax.set_xlabel('BMI')
ax.set_ylabel('Progression')
ax.set_title(f'SLR: Progression ~ BMI   ($R^2$ = {model_slr.rsquared:.3f})')
ax.legend()
plt.tight_layout()
plt.show()
