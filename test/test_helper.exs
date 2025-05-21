{:ok, _app} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(PurseCraft.Repo, :manual)
Faker.start()

Mimic.copy(PurseCraft.Budgeting.Policy)
Mimic.copy(PurseCraft.Budgeting)
Mimic.copy(PurseCraft.Budgeting.Commands.PubSub.BroadcastBook)
Mimic.copy(PurseCraft.Budgeting.Commands.PubSub.BroadcastUserBook)
