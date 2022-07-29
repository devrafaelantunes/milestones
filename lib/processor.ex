defmodule Milestones.Processor do
  @moduledoc """
    Processes a CSV file containing employee data and stores it in the cache for later use.

    You can set up the cache name and the file path on the `config.exs` file. The file presented
    there will be loaded and parsed as soon as the application starts.

    The employee data CSV must follow the file example format found in `data/employee_data.csv`

    You can also recompile the file in runtime using `Processor.recompile()` so there is no need to
    reload your application.

    The file loading is handled by Flow, which improves the file's reading and parsing by computating
    its content in parallel using GenStage, thus enhancing the app's performance.

    After loading and parsing the file, its content will be stored in an ETS table. The table will act
    as a cache for the `Milestones.Report` module.
  """

  require Logger

  # Retrieves the cache name and file path from the config file
  @table_name Application.get_env(:milestones, :table_name)
  @file_path Application.get_env(:milestones, :employee_data_path)

  @doc """
    Loads and parses the CSV file presented in the config.exs file as soon as the app starts. It also
    creates an ETS table to act like a cache.

    If the file does not exist, the table won't be created.
  """
  @spec start(String.t() | none()) :: Logger.t()
  def start(file_path \\ @file_path) do
    # Checks if the file exists before streaming it
    case File.exists?(file_path) do
      true ->
        # Creates an ETS table based on the name presented in the config.exs file
        :ets.new(@table_name, [:duplicate_bag, :public, :named_table])

        file_path
        |> File.stream!()
        |> parse_file()

        Logger.info("#{file_path} has been read and stored successfully")

        {:ok, :file_read_and_stored}

      false ->
        Logger.warn("File #{file_path} not found")

        {:error, :file_not_found}
    end
  end

  @doc """
    Repopulate the cache in runtime without having to reload the application
  """
  @spec recompile(String.t() | none()) :: Logger.t()
  def recompile(file_path \\ @file_path) do
    :ets.delete(@table_name)

    Logger.info("#{file_path} was reloaded successfully")

    start(file_path)
  end

  # Parses the file using Stream and Flow to improve its performance.
  @spec parse_file(file :: Stream.t()) :: Flow.t()
  def parse_file(file) do
    file
    # Drop the headers presented in the file ("employee_id, first_name...")
    |> Stream.drop(1)
    |> Flow.from_enumerable()
    # Filters out the empty contents
    |> Flow.filter(fn input -> input != "" end)
    |> Flow.partition()
    |> Flow.map(fn employee_data ->
      employee_data = String.replace(employee_data, "\n", "")

      [employee_id, _first_name, _last_name, hire_date, supervisor_id] =
        String.split(employee_data, ",")

      case Date.from_iso8601(hire_date) do
        {:ok, updated_hire_date} ->
          info = %{
            employee_id: employee_id,
            hire_date: updated_hire_date
          }

          # Insert the employee in the ETS table under his supervisor_id key
          :ets.insert(@table_name, {supervisor_id, info})

        _ ->
          Logger.warn("Search date must be a string in the iso8601 format (year-month-day)")
      end
    end)
    |> Flow.run()
  end
end
