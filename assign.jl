import Pkg
Pkg.add("JuMP")
Pkg.add("HiGHS")

using JuMP
using HiGHS
using CSV
using DataFrames
using Printf

studentPrefs = CSV.File("/files/lab-pref.csv") |> DataFrame
select!(studentPrefs, Not(:Timestamp))
select!(studentPrefs, Not("Did you think of gaming this?"))

numStudents = nrow(studentPrefs)

# How many people can labs on that day take; in 2024, one lab each Mon and Thu, two on Wed
days = [("Monday", 20), ("Wednesday", 40), ("Thursday", 20)]
dayNames = [p[1] for p in days]
daySize = [p[2] for p in days]
numDays = length(daySize)

function convert_choice(choice)
    if startswith(choice, "Really, absolutely")  # can't make it!
        return 10000000                          # would be nice to use Inf, but default solver expects finite values
    elseif choice == "Third choice"
        return 10000
    elseif choice == "Second choice"
        return 100
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
    @printf("%s: %i\n", days[dayNum][1], value(sum(seated[i, dayNum] for i in 1:numStudents)))
end

print("Objective value: ")
println(objective_value(model))
