import Pkg
Pkg.add("JuMP")
Pkg.add("HiGHS")

using JuMP
using HiGHS
using CSV
using DataFrames
using Printf

# Expect the CSV file path as the first command-line argument.
if length(ARGS) < 1
    println("Usage: julia assign.jl <csv-file>")
    println("Example: julia assign.jl lab-pref.csv")
    exit(1)
end

csv_path = ARGS[1]
if !isfile(csv_path)
    error("Input file not found: " * csv_path)
end

studentPrefs = CSV.File(csv_path) |> DataFrame
select!(studentPrefs, Not(:Timestamp))

numStudents = nrow(studentPrefs)

days = [("Monday", 20), ("Wednesday", 40), ("Thursday", 20)]
# How many people can labs take; students are assigned to whatever "keys" are used below, so multiple labs on a day just need different keys
# These must be in the SAME order as the column headers in the CSV!
dayNames = [p[1] for p in days]
daySize = [p[2] for p in days]
numDays = length(daySize)

function convert_choice(choice)
    if startswith(choice, "Really, absolutely")  # can't make it!
        return 100000                          # would be nice to use Inf, but default solver expects finite values
    elseif choice == "Third choice"
        return 1000
    elseif choice == "Second choice"
        return 50
    elseif choice == "First choice"
        return 1
    else
        error("Unexpected choice: " * choice)
    end
end

for col in [string(i) for i in 1:numDays]
    studentPrefs[!, col] .= [convert_choice(choice) for choice in studentPrefs[!, col]]
end

model = Model(HiGHS.Optimizer)

@variable(model, seated[1:numStudents, 1:numDays], Bin)

for dayNum in 1:numDays
    @constraint(model, sum(seated[i, dayNum] for i in 1:numStudents) <= daySize[dayNum])
end

for studentNum in 1:numStudents
    @constraint(model, 1 <= sum(seated[studentNum, j] for j in 1:numDays) <= 1)  # can't write = 1…
end

# The + 1 below is because the first column of the DataFrame is Email Address, so we want the second one onward
@objective(model, Min, sum(studentPrefs[i, j + 1] * seated[i, j] for i in 1:numStudents, j in 1:numDays))

optimize!(model)
if is_solved_and_feasible(model)
    @printf("\n\nSOLUTION FOUND!\n\n")
else
    error("Solver did not find an optimal solution")
end

maxNameWidth = maximum(length.(studentPrefs[!, "Email Address"]))

for studentNum in 1:numStudents
    print(@sprintf("%*s: ", maxNameWidth, studentPrefs[studentNum, "Email Address"]))
    for dayNum in 1:numDays
        if value(seated[studentNum, dayNum]) == 1.0
	    println(days[dayNum][1])
	end
    end
end

for dayNum in 1:numDays
    println(days[dayNum][1])
    for studentNum in 1:numStudents
    	if value(seated[studentNum, dayNum]) == 1.0
	   println(studentPrefs[studentNum, "Email Address"])
	end
    end
    println("-----")
end

for dayNum in 1:numDays
    @printf("%s: %i\n", days[dayNum][1], value(sum(seated[i, dayNum] for i in 1:numStudents)))
end

print("Objective value: ")
println(objective_value(model))
