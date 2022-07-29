defmodule Milestones.ReportTest do
  use ExUnit.Case

  alias Milestones.Report
  import ExUnit.CaptureIO

  setup do
    file_path = "test/fixtures/employee_data.csv"

    Milestones.Processor.start(file_path)

    :ok
  end

  describe "generate_by_supervisor_id/2" do
    test "should return error when inputting the wrong format" do
      assert Report.generate_by_supervisor_id(:wrong, :format) ==
               {:error, :wrong_arguments_format}
    end

    test "should return error when inputting the wrong format only on one argument" do
      assert Report.generate_by_supervisor_id("supervisor", :format) ==
               {:error, :wrong_arguments_format}
    end

    test "should return error when `supervisor_id` cannot be found" do
      assert Report.generate_by_supervisor_id("unknown_supervisor", "2020-10-10") ==
               {:error, :supervisor_id_not_found}
    end

    test "should return milestone list when both arguments are passed correctly" do
      expected_report = [
        %{anniversary_date: "2023-01-25", employee_id: "drutledge166"},
        %{anniversary_date: "2028-01-25", employee_id: "drutledge166"},
        %{anniversary_date: "2033-01-25", employee_id: "drutledge166"},
        %{anniversary_date: "2038-01-25", employee_id: "drutledge166"},
        %{anniversary_date: "2043-01-25", employee_id: "drutledge166"}
      ]

      generated_report = Report.generate_by_supervisor_id("jbrady157", "2020-05-05")

      assert generated_report == expected_report
      assert length(generated_report) == 5

      first_milestone_example = Enum.at(generated_report, 0)
      second_milestone_example = Enum.at(generated_report, 1)

      assert first_milestone_example.employee_id == "drutledge166"

      {:ok, first_anniversary_date} = Date.from_iso8601(first_milestone_example.anniversary_date)

      {:ok, second_anniversary_date} =
        Date.from_iso8601(second_milestone_example.anniversary_date)

      assert Date.compare(first_anniversary_date, second_anniversary_date) == :lt
    end
  end

  describe "generate_all_milestones/1" do
    test "should return error when inputting the wrong format" do
      assert Report.generate_all_milestones(:wrong_format) ==
               {:error, :wrong_arguments_format}
    end

    test "should return milestone list when both arguments are passed correctly" do
      supervisors_list = ["ballison200", "jbrady157"]

      generated_report = Report.generate_all_milestones("2020-05-05")
      assert Map.keys(generated_report) == supervisors_list

      {_supervisor_id, first_employees_list} = Enum.at(generated_report, 0)
      {_supervisor_id, second_employees_list} = Enum.at(generated_report, 1)

      assert length(first_employees_list) == 5
      assert length(second_employees_list) == 5

      {:ok, first_anniversary_date} =
        Enum.at(first_employees_list, 0).anniversary_date
        |> Date.from_iso8601()

      {:ok, second_anniversary_date} =
        Enum.at(first_employees_list, 1).anniversary_date
        |> Date.from_iso8601()

      assert Date.compare(first_anniversary_date, second_anniversary_date) == :lt
    end
  end

  describe "parse_file_and_generate_all_milestones/2" do
    test "should return error when inputting the wrong format" do
      assert Report.parse_file_and_generate_all_milestones(:wrong, :format) ==
               {:error, :wrong_arguments_format}
    end

    test "should return error when file is not found" do
      assert Report.parse_file_and_generate_all_milestones("2020-10-05", "unknown_file") ==
               {:error, :file_not_found}
    end

    test "should return milestone list when both arguments are passed correctly" do
      old_file_supervisors_list = ["ballison200", "jbrady157"]

      generated_report =
        Report.parse_file_and_generate_all_milestones(
          "2020-05-05",
          "test/fixtures/reloaded_employee_data.csv"
        )

      refute Map.keys(generated_report) == old_file_supervisors_list

      assert Map.keys(generated_report) == ["ballison200"]

      {_supervisor_id, employees_list} = Enum.at(generated_report, 0)

      assert length(employees_list) == 5

      {:ok, first_anniversary_date} =
        Enum.at(employees_list, 0).anniversary_date
        |> Date.from_iso8601()

      {:ok, second_anniversary_date} =
        Enum.at(employees_list, 1).anniversary_date
        |> Date.from_iso8601()

      assert Date.compare(first_anniversary_date, second_anniversary_date) == :lt
    end
  end
end
