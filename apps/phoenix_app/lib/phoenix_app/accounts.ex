defmodule PhoenixApp.Accounts do
  use Ash.Domain

  resources do
    resource PhoenixApp.Accounts.User
  end
end
