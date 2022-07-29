defmodule Milestones.Report do
  @moduledoc """
    Module responsible for generating a report containing the next 5 employees' milestones dates.

    These are the types of reports the app can generate:
    - `parse_file_and_generate_all_milestones/2`
      * It parses the CSV file passed as an argument and returns all the milestones for all
      supervisors based on a search date.

    - `generate_all_milestones/1`
      * Fetches the employees information from the cache and return all the milestones for all
      supervisores based on a search date.

    - `generate_by_supervisor_id/2`
      * Fetches the employees information from the cache as well, but it will only return the
      milestones for a specific supervisor based on a search date.
  """

  @table_name Application.get_env(:milestones, :table_name)

  @type search_date() :: String.t()

  @doc """
    Generates a milestone reports for all supervisors based on a search_date and a CSV file.

    `search_date` must be a string built based on the following format: "year-month-day".
    `file_name` must also be a string containing the path of a CSV file containing the employee
    data.
  """
  @spec parse_file_and_generate_all_milestones(search_date(), file_name :: String.t()) ::
          {:ok, :milestone_list_generated} | {:error, :file_not_found}
  def parse_file_and_generate_all_milestones(search_date, file_name)
      when is_binary(search_date) and is_binary(file_name) do
    # Removes the loaded file from the cache
    :ets.delete(@table_name)

    case Milestones.Processor.start(file_name) do
      {:ok, :file_read_and_stored} ->
        generate_all_milestones(search_date)

      error ->
        error
    end
  end

  @spec parse_file_and_generate_all_milestones(any(), any()) :: {:error, :wrong_arguments_format}
  def parse_file_and_generate_all_milestones(_, _), do: {:error, :wrong_arguments_format}

  @doc """
    Generates a milestone report based on the `supervisor_id` and `search_date`.

    The `supervisor_id` must also be a string and exist on the `employee_data` cache. To find
    out how to store the employee data, check the `Milestones.Processor` module.

    The function will return a map containing the next 5 milestones ordered by date. It uses
    the Apex library to pretty print the report struct.

    In a scenario where the `supervisor_id` is invalid, the function will return an :error tuple
  """
  @spec generate_by_supervisor_id(supervisor_id :: String.t(), search_date()) ::
          {:ok, :milestone_list_generated} | {:error, :supervisor_id_not_found}
  def generate_by_supervisor_id(supervisor_id, search_date)
      when is_binary(supervisor_id) and is_binary(search_date) do
    case :ets.lookup(@table_name, supervisor_id) do
      [] ->
        {:error, :supervisor_id_not_found}

      list_of_employees ->
        # Parses the Date
        {:ok, search_date} = Date.from_iso8601(search_date)

        milestone_list = generate_single_milestones_list(list_of_employees, search_date)

        parse_response(milestone_list)
    end
  end

  @spec generate_by_supervisor_id(any(), any()) :: {:error, :wrong_arguments_format}
  def generate_by_supervisor_id(_, _), do: {:error, :wrong_arguments_format}

  @doc """
    Generates all milestones for all supervisors based on a search_date
  """
  @spec generate_all_milestones(search_date()) ::
          {:ok, :milestone_list_generated} | {:error, :table_not_found}
  def generate_all_milestones(search_date) when is_binary(search_date) do
    case :ets.info(@table_name) do
      :undefined ->
        {:error, :table_not_found}

      _ ->
        {:ok, search_date} = Date.from_iso8601(search_date)

        :ets.tab2list(@table_name)
        |> generate_all_milestones_list(search_date)
        |> parse_response()
    end
  end

  @spec generate_all_milestones(any()) :: {:error, :wrong_arguments_format}
  def generate_all_milestones(_), do: {:error, :wrong_arguments_format}

  @spec parse_response(list(map)) :: {:ok, :milestone_list_generated} | list(map())
  defp parse_response(milestone_list) do
    if Mix.env() != :test do
      Apex.ap(milestone_list, numbers: false)

      {:ok, :milestone_list_generated}
    else
      milestone_list
    end
  end

  @spec generate_all_milestones_list(list_of_employees :: list(tuple()), search_date()) :: map()
  defp generate_all_milestones_list(list_of_employees, search_date) do
    list_of_employees
    |> Enum.map(fn {supervisor_id, employees} ->
      top_5 =
        [employees]
        |> Enum.reduce({[], {search_date, nil}}, fn employee, {top_5, {min_date, max_date}} ->
          # This function will create a recursion to fill the `top_5` list present on the acc
          process_employee(employee, top_5, {min_date, max_date})
        end)
        |> elem(0)
        |> Enum.map(fn x ->
          # Parses the employee data to fit the desired report struct
          %{anniversary_date: to_string(x.anniversary_date), employee_id: x.employee_id}
        end)

      {supervisor_id, top_5}
    end)
    |> Map.new()
  end

  @spec generate_single_milestones_list(list_of_employees :: list(tuple()), search_date()) ::
          list(map())
  defp generate_single_milestones_list(list_of_employees, search_date) do
    list_of_employees
    |> Enum.reduce({[], {search_date, nil}}, fn {_supervisor_id, employee},
                                                {top_5, {min_date, max_date}} ->
      # This function will create a recursion to fill the `top_5` list present on the acc
      process_employee(employee, top_5, {min_date, max_date})
    end)
    |> elem(0)
    |> Enum.map(fn x ->
      # Parses the employee data to fit the desired report struct
      %{anniversary_date: to_string(x.anniversary_date), employee_id: x.employee_id}
    end)
  end

  @spec process_employee(employee :: map(), top_5 :: list(), {Date.t(), Date.t()}) ::
          {list(map), {Date.t(), Date.t()}}
  defp process_employee(%{hire_date: hire_date} = employee, top_5, {min_date, max_date}) do
    # Calculates the employee's next milestone based on his hire date
    next_milestone = get_next_milestone(hire_date, min_date)

    # Adds the employee to the milestones list
    add_to_top_5 = fn ->
      (top_5 ++ [%{employee_id: employee.employee_id, anniversary_date: next_milestone}])
      # Sorts the list by Date
      |> Enum.sort_by(& &1.anniversary_date, Date)
      # Returns only the first 5 results
      |> Enum.take(5)
    end

    if is_nil(max_date) or Date.diff(next_milestone, max_date) < 0 do
      top_5 = add_to_top_5.()
      employee = Map.put(employee, "hire_date", next_milestone)
      process_employee(employee, top_5, {next_milestone, get_max_date(top_5)})
    else
      min_date = get_min_date(top_5)
      {top_5, {min_date, max_date}}
    end
  end

  @spec get_next_milestone(tentative_date :: Date.t(), min_date :: Date.t()) :: Date.t()
  defp get_next_milestone(tentative_date, min_date) do
    # Creates a recursion until it finds the next milestone
    if Date.diff(tentative_date, min_date) <= 0 do
      new_tentative_date =
        Date.new!(tentative_date.year + 5, tentative_date.month, tentative_date.day)

      get_next_milestone(new_tentative_date, min_date)
    else
      tentative_date
    end
  end

  @spec get_min_date(list()) :: Date.t()
  defp get_min_date([first_entry | _]), do: first_entry.anniversary_date

  @spec get_max_date(list()) :: nil
  defp get_max_date(entries) when length(entries) < 5, do: nil

  @spec get_max_date(list()) :: Date.t()
  defp get_max_date([_, _, _, _, last_entry]), do: last_entry.anniversary_date
end
