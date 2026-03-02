defmodule PhoenixApp.Accounts.UserTest do
  use PhoenixApp.DataCase, async: true

  alias PhoenixApp.Accounts.User

  require Ash.Query

  describe "upsert_from_clerk" do
    test "creates a new user from Clerk claims" do
      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:upsert_from_clerk, %{
          clerk_id: "user_clerk_001",
          email: "alice@example.com",
          org_id: "org_abc",
          display_name: "Alice"
        })
        |> Ash.create(authorize?: false)

      assert user.clerk_id == "user_clerk_001"
      assert user.email == "alice@example.com"
      assert user.org_id == "org_abc"
      assert user.display_name == "Alice"
    end

    test "upsert is idempotent — same clerk_id yields one record" do
      attrs = %{
        clerk_id: "user_clerk_002",
        email: "bob@example.com",
        org_id: nil,
        display_name: "Bob"
      }

      {:ok, user1} =
        User
        |> Ash.Changeset.for_create(:upsert_from_clerk, attrs)
        |> Ash.create(authorize?: false)

      {:ok, user2} =
        User
        |> Ash.Changeset.for_create(:upsert_from_clerk, attrs)
        |> Ash.create(authorize?: false)

      assert user1.id == user2.id

      count =
        User
        |> Ash.read!(authorize?: false)
        |> Enum.count(fn u -> u.clerk_id == "user_clerk_002" end)

      assert count == 1
    end

    test "upsert updates changed fields" do
      {:ok, _user1} =
        User
        |> Ash.Changeset.for_create(:upsert_from_clerk, %{
          clerk_id: "user_clerk_003",
          email: "carol@example.com",
          org_id: nil,
          display_name: "Carol"
        })
        |> Ash.create(authorize?: false)

      {:ok, user2} =
        User
        |> Ash.Changeset.for_create(:upsert_from_clerk, %{
          clerk_id: "user_clerk_003",
          email: "carol.new@example.com",
          org_id: "org_new",
          display_name: "Carol Updated"
        })
        |> Ash.create(authorize?: false)

      assert user2.email == "carol.new@example.com"
      assert user2.org_id == "org_new"
      assert user2.display_name == "Carol Updated"
    end

    test "policy allows actor to read their own record" do
      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:upsert_from_clerk, %{
          clerk_id: "user_clerk_004",
          email: "dave@example.com",
          org_id: nil,
          display_name: "Dave"
        })
        |> Ash.create(authorize?: false)

      # Actor reads their own record
      user_id = user.id

      result =
        User
        |> Ash.Query.filter(id == ^user_id)
        |> Ash.read!(actor: user)

      assert length(result) == 1
      assert hd(result).id == user.id
    end
  end
end
