defmodule TdBg.RepoTest do
  use TdBg.DataCase

  alias TdBg.Repo
  alias TdBg.Taxonomies.Domain

  describe "stream_preload/4" do
    test "preloads associations on chunks of a stream" do
      Repo.transaction(fn ->
        parent = insert(:domain, name: "Parent")
        insert(:domain, parent: parent, name: "Child1")
        insert(:domain, parent: parent, name: "Child2")
        insert(:domain, parent: parent, name: "Child3")

        query =
          from(d in Domain,
            where: d.parent_id == ^parent.id,
            order_by: d.id
          )

        stream = Repo.stream(query, max_rows: 2)
        result = Repo.stream_preload(stream, 2, [:parent])

        domains = Enum.to_list(result)

        assert length(domains) == 3
        assert Enum.at(domains, 0).name == "Child1"
        assert Enum.at(domains, 0).parent.name == "Parent"
        assert Enum.at(domains, 1).name == "Child2"
        assert Enum.at(domains, 1).parent.name == "Parent"
        assert Enum.at(domains, 2).name == "Child3"
        assert Enum.at(domains, 2).parent.name == "Parent"
      end)
    end

    test "handles empty stream" do
      Repo.transaction(fn ->
        query = from(d in Domain, where: d.id == -1)
        stream = Repo.stream(query)
        result = Repo.stream_preload(stream, 10, [:parent])

        assert [] = Enum.to_list(result)
      end)
    end

    test "handles stream with single element" do
      domain = insert(:domain, name: "Single")

      Repo.transaction(fn ->
        query = from(d in Domain, where: d.id == ^domain.id)
        stream = Repo.stream(query)
        result = Repo.stream_preload(stream, 10, [])

        [loaded] = Enum.to_list(result)
        assert loaded.id == domain.id
      end)
    end

    test "preloads multiple associations" do
      parent = insert(:domain, name: "Parent")
      child = insert(:domain, parent: parent, name: "Child")

      Repo.transaction(fn ->
        query = from(d in Domain, where: d.id == ^child.id)
        stream = Repo.stream(query)

        [loaded] =
          stream
          |> Repo.stream_preload(10, [:parent])
          |> Enum.to_list()

        assert loaded.parent.name == "Parent"
      end)
    end
  end

  describe "init/2" do
    test "returns opts with url from DATABASE_URL environment variable" do
      original_env = System.get_env("DATABASE_URL")
      System.put_env("DATABASE_URL", "postgresql://test:test@localhost:5432/test")

      try do
        assert {:ok, opts} = Repo.init(:extra_arg, [])
        assert opts[:url] == "postgresql://test:test@localhost:5432/test"
      after
        if original_env do
          System.put_env("DATABASE_URL", original_env)
        else
          System.delete_env("DATABASE_URL")
        end
      end
    end
  end
end
