---
title: "Numeric Methods for Option Pricing"
author: "John Robin Inston"
date: "2025-11-01"
draft: true
categories: [Quantitative Finance, Option Pricing, Python]
toc: true
title-block-banner: true
---

## Introduction

In _Financial Mathematics_ we are interested in pricing financial derivatives (most commonly options) whose payoffs are complicated functions of stochastic pricess processes that are often not solveable analytically.  In this project we explore the three main approaches for numerically solving these pricing problems:

1. _Monte-Carlo (MC)_ Methods,
2. _Partial Differential Equations (PDEs)_, and
3. Surrogate Methods. 

Throughout the project we will provide example code applying the described method using `python`.  A detailed discussion of the mathematical theory of financial models and option pricing is reserved for a seperate note.  This project was informed by materials provided by [Prof. Michael Ludkovski](https://ludkovski.pstat.ucsb.edu) through his PSTAT222: Computational Finance course which I took in Spring 2024.  The source material for this course was the textbook [An Introduction to the Numerical Simulation of Stochastic Differential Equations by Higham & Kloeden](https://epubs.siam.org/doi/book/10.1137/1.9781611976434).  All material produced in this project can be found in the following [GitHub repository]().

## SDE Monte-Carlo Methods

### Motivating Example

Assume that a stock price is described by a continuous-time stochastic process with dynamics given by the stochastic differential equation (SDE)
$$
dX_t = 
$$




Consider a call option on the general SD


Suppose that we wish to numerically solve the general SDE
$$
dX(t)=f(t,X(t))dt+g(t,X(t))dW(t),
$$

on $0 \leq t \leq T$ with given initial $X(0)=x$.  By definition, the exact solution is given by
$$
X(t)-X(t_{0})=\int_{t_{0}}^t f(s,X_{s})ds+\int_{t_{0}}^t g(s,X(s))dW(s).
$$



### Euler-Maruyama Algorithm
