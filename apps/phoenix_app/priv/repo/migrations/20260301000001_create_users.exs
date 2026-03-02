defmodule PhoenixApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :clerk_id, :string, null: false
      add :email, :string, null: false
      add :org_id, :string
      add :display_name, :string

      timestamps()
    end

    create unique_index(:users, [:clerk_id])
  end
end
