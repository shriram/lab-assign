# Lab Assignment

## What It Is

This repository uses integer programming to assign students to labs
based on their preferences.

There is nothing “lab”-specific about it. The program is quite general
and should be usable for a variety of situations where students
provide preferences and are assigned to some kind of section.

## Preferences

The program hard-codes one of the following four student preferences:

- First choice
- Second choice
- Third choice
- Really, absolutely, totally cannot make

The function `convert_choice` maps these to numbers. Modify this at
will, including (especially) the relative weight of these preferences.

Use the filename `lab-pref.csv`.

## Data File Format and Alteration

The preference file is assumed to be a CSV with the following headers,
in this order:

- `Timestamp`
- `Email Address`
- the actual labs…

The first two fields are consistent with using Google Forms to get
student preferences, and saving to a Google Sheet.

The actual labs should be renamed to `1`, `2`, `3`, etc. in the CSV,
because the program depends on that. The actual names in the original
may be much more elaborate (e.g., if generated from a Google Form,
they may be designations of the actual lab: days and times), but this
gets very awkward to process. This manual step saves this pain.

You can have any number of additional fields that don't begin with
sequential integers. They will be ignored.

## Program Modifications

You will need to edit the code to indicate the days and available
spaces for each day. Currently it reads:
```
days = [("Monday", 20), ("Wednesday", 40), ("Thursday", 20)]
```
That means Monday has 20 lab seats, Wednesday has 40, etc.

The program has been fairly well parameterized, so that with the above
modifications, everything else is read off of them. Of course, if you
run into problems, let me know.

## Dependencies

The program depends on the following Julia packages:

- [`JuMP`](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/getting_started_with_JuMP/#Getting-started-with-JuMP)
- HiGHS solver (which JuMP installs from commands in the program)
- `CSV`
- `DataFrames`
- `Printf`

## Build

Build a fresh Docker image with all dependencies preinstalled:

```
make build-image
```

Optional: pin a specific Julia minor version during build (e.g., 1.11):

```
make build-image JULIA_VERSION=1.11
```

This creates an image named `lab-assign`.

## Run

The program expects the CSV filename as a command-line argument.
Run it directly using the built image:

```
docker run --rm -v "$PWD":/files lab-assign:latest julia /files/assign.jl /files/lab-pref.csv
```

## Test Files

The repository includes several test CSV files to verify the solver's behavior under different scenarios. All test files use the same 10 students: Aisha, Chen, Dmitri, Emeka, Fatima, Giovanni, Haruki, Indira, Javier, and Keiko.

### `all-first.csv`
**Scenario:** Every student marks all three labs as "First choice".  
**Expected outcome:** Solver should easily find a solution distributing students across days. All students should get their first choice (since every day is a first choice). Objective value should be 10 (10 students × 1 point each).

### `all-avail.csv`
**Scenario:** Everyone is available for all days, but with varied preferences (mix of first, second, and third choices spread across students and days).  
**Expected outcome:** Solver should find an optimal solution that minimizes the total preference cost. Most students should get their first or second choice.

### `one-cant.csv`
**Scenario:** Giovanni cannot attend any day (all marked as "Really, absolutely, totally cannot make").  
**Expected outcome:** The solver should technically fail to find a feasible solution, since Giovanni cannot be assigned anywhere. In practice it finds one since Giovanni's inability turns into a very high score, so the objective value is also very high.

### `one-third.csv`
**Scenario:** Giovanni marks all three labs as "Third choice" while others have varied preferences.  
**Expected outcome:** Solver should find a solution, but Giovanni will likely be assigned last after accommodating others' stronger preferences. Giovanni's assignment will increase the objective value noticeably.

### `balanced-demand.csv`
**Scenario:** Student preferences are evenly distributed across all three days—roughly equal numbers prefer each day as their first choice.  
**Expected outcome:** Solver should easily distribute students across all days with most getting their first choice. Low objective value, balanced day assignments.

### `one-day-dominates.csv`
**Scenario:** All 10 students prefer day 1 (Monday) as first choice, with days 2 and 3 as fallback options.  
**Expected outcome:** With Monday's 20-seat capacity, all 10 can fit on Monday. If capacity were tighter, the solver would distribute students based on their second/third preferences to minimize total cost.

### `cascading-prefs.csv`
**Scenario:** All students have identical preference order: Mon (first) > Wed (second) > Thu (third).  
**Expected outcome:** Solver distributes students uniformly, likely filling Monday first, then Wednesday, then Thursday, since all have the same preference pattern. Everyone gets the same relative preference satisfaction.

### `mixed-availability.csv`
**Scenario:** Mix of students with full availability (all first choices), partial constraints (some "cannot make" entries), and varying preference levels.  
**Expected outcome:** Solver must navigate around "cannot make" constraints while optimizing preferences. Students with more constraints may get less preferred slots. Solution should be feasible and show how constraints affect assignments.

### `minimum-viable.csv`
**Scenario:** Each student can attend only one or two specific days (many "cannot make" entries), creating tight constraints.  
**Expected outcome:** Solver should find a solution if one exists, but it will be highly constrained. This tests whether the combination of individual constraints still allows a feasible assignment. May result in higher objective value due to limited flexibility.

### `two-way-split.csv`
**Scenario:** Half the students prefer days 1-2, the other half prefer days 2-3, creating competition for day 2 (Wednesday).  
**Expected outcome:** Solver should balance assignments to minimize cost. Day 2 may be popular but has high capacity (40 seats), so most students should get their top choices. Tests the solver's ability to handle competing demands for a shared resource.

### `polarized-prefs.csv`
**Scenario:** Five students prefer day 1 and cannot make day 3; five students prefer day 3 and cannot make day 1. Day 2 (Wednesday) is a fallback for both groups.  
**Expected outcome:** Solver should assign each group to their preferred day. With Mon=20 and Thu=20, both groups (5 students each) fit comfortably. This tests the solver's handling of mutually exclusive preferences.
