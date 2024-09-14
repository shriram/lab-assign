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
- `Did you think of gaming this?`

The first two fields are consistent with using Google Forms to get
student preferences, and saving to a Google Sheet.

The actual labs should be renamed to `1`, `2`, `3`, etc. in the CSV,
because the program depends on that. The actual names in the original
may be much more elaborate (e.g., if generated from a Google Form,
they may be designations of the actual lab: days and times), but this
gets very awkward to process. This manual step saves this pain.

## Program Modifications

The last field was a joke field present in a form the first time this
program was used. If you remove that field from the form, also remove
the line of code
```
select!(studentPrefs, Not("Did you think of gaming this?"))
```
(Someday all this may be much more parameterized…this is not that
day.)

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

## Personal Note

I currently have a Docker image that has all of these built: `julia-jump-highs-csv-dataframes`.

Run it using
```
docker run -v`pwd`:/files -ti julia-jump-highs-csv-dataframes
```
and from inside Julia, run:
```
include("/files/assign.jl")
```

