## Milestones

It is common in our recognition programs for supervisors to need assistance planning for their direct reports' milestone anniversaries. This app outputs a list of upcoming anniversaries to assist on the milestone planning.

## How the application works

Once started the app will read and parse a CSV file by default stored at `data/employee_data.csv`. After reading it, the app will store its information on an ETS table that acts as a cache. 

Most of the reports the app is able to generate will rely on that cache to be produced. This behaviour removes the need to parse the CSV file each time we need a new report.

The table name and file path are configurable at `config/config.exs` file.
You can also recompile the cache in runtime by using `Milestones.Report.recompile/1`.

Instead of relying on a static configuration, you can also pass the file path as an argument to the `Milestones.Report.parse_file_and_generate_all_milestones/2` function, so a report can be generated based on that dynamic file.

To read and parse files, Milestones uses the Flow library to increase its performance.

For more information please visit the `Milestones.Processor` and `Milestones.Report` modules.

## How to use it

There are three types of reports the app can generate:
- `Milestones.Report.parse_file_and_generate_all_milestones/2`
    * It parses the CSV file passed as an argument and returns all the milestones for all
    supervisors based on a search date.

- `Milestones.Report.generate_all_milestones/1`
    * Fetches the employees information from the cache and return all the milestones for all supervisores based on a search date.

- `Milestones.Report.generate_by_supervisor_id/2`
    * Fetches the employees information from the cache as well, but it will only return the milestones for a specific supervisor based on a search date.

The search date must be a string on this format: "year-month-day"

## How to run the application

- clone the repository
- `mix deps.get`
- `iex -S mix`

## How to run unit tests

- use `mix test`



- Created by: Rafael Antunes.

