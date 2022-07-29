defmodule Milestones.Application do
  use Application

  def start(_type, _args) do
    children = []

    if Mix.env() != :test do
      Milestones.Processor.start()
    end

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
