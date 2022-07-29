defmodule Milestones.ProcessorTest do
  use ExUnit.Case

  alias Milestones.Processor

  import ExUnit.CaptureLog
  require Logger

  @table_name Application.get_env(:milestones, :table_name)
  @file_path "test/fixtures/employee_data.csv"

  describe "start/1" do
    test "should parse file and create ets table when file exists" do
      example_supervisor_id = "jbrady157"

      assert :ets.info(@table_name) == :undefined

      assert capture_log(fn ->
               Processor.start(@file_path)
             end) =~ "#{@file_path} has been read and stored successfully"

      # Check if the ETS table was created
      refute :ets.info(@table_name) == :undefined

      # Check if the ETS is not empty
      refute :ets.tab2list(@table_name) == []

      employee_data = :ets.lookup(@table_name, example_supervisor_id)

      assert employee_data == [
               {"jbrady157", %{employee_id: "drutledge166", hire_date: ~D[1993-01-25]}}
             ]
    end

    test "shouldn't read unexisting file" do
      wrong_file_name = "lala"

      assert :ets.info(@table_name) == :undefined

      assert capture_log(fn ->
               Processor.start(wrong_file_name)
             end) =~ "File #{wrong_file_name} not found"

      assert :ets.info(@table_name) == :undefined
    end
  end

  describe "recompile/1" do
    test "file is recompilled" do
      example_supervisor_id = "jbrady157"
      reloaded_file_path = "test/fixtures/reloaded_employee_data.csv"

      assert :ets.info(@table_name) == :undefined

      assert capture_log(fn ->
               Processor.start(@file_path)
             end) =~ "#{@file_path} has been read and stored successfully"

      # When the app started this supervisor was present on the file
      employee_data = :ets.lookup(@table_name, example_supervisor_id)

      assert employee_data == [
               {"jbrady157", %{employee_id: "drutledge166", hire_date: ~D[1993-01-25]}}
             ]

      # Recompiling the file to remove the "jbrady157" supervisor ID
      assert capture_log(fn ->
               Processor.recompile(reloaded_file_path)
             end) =~ "#{reloaded_file_path} was reloaded successfully"

      # This supervisor was removed from the file
      assert :ets.lookup(@table_name, example_supervisor_id) == []
    end
  end
end
