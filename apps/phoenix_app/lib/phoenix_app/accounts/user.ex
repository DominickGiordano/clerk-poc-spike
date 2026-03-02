defmodule PhoenixApp.Accounts.User do
  use Ash.Resource,
    domain: PhoenixApp.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "users"
    repo PhoenixApp.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :clerk_id, :string do
      allow_nil? false
    end

    attribute :email, :string do
      allow_nil? false
    end

    attribute :org_id, :string
    attribute :display_name, :string

    timestamps()
  end

  identities do
    identity :clerk_id, [:clerk_id]
  end

  actions do
    defaults [:read]

    create :upsert_from_clerk do
      accept [:clerk_id, :email, :org_id, :display_name]
      upsert? true
      upsert_identity :clerk_id
      upsert_fields [:email, :org_id, :display_name]
    end
  end

  policies do
    # Users can read their own record
    policy action_type(:read) do
      authorize_if expr(id == ^actor(:id))
    end

    # Allow upsert_from_clerk without actor (system action during auth)
    policy action(:upsert_from_clerk) do
      authorize_if always()
    end
  end
end
