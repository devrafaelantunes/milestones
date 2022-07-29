import Config

config :milestones,
  table_name: :employee_data

if config_env() != :test do
  config :milestones,
    employee_data_path: "data/employee_data.csv"
end
