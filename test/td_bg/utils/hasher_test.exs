defmodule TdBg.Utils.HasherTest do
  use ExUnit.Case

  alias TdBg.Utils.Hasher

  describe "hash_file/2" do
    test "hashes a file with MD5 by default" do
      {:ok, path} = create_temp_file("test content")
      hash = Hasher.hash_file(path)
      assert is_binary(hash)
      assert String.length(hash) == 32
      cleanup_temp_file(path)
    end

    test "hashes a file with MD5 explicitly" do
      {:ok, path} = create_temp_file("test content")
      hash = Hasher.hash_file(path, :md5)
      assert is_binary(hash)
      assert String.length(hash) == 32
      cleanup_temp_file(path)
    end

    test "hashes a file with SHA1" do
      {:ok, path} = create_temp_file("test content")
      hash = Hasher.hash_file(path, :sha)
      assert is_binary(hash)
      assert String.length(hash) == 40
      cleanup_temp_file(path)
    end

    test "returns consistent hash for same content" do
      {:ok, path1} = create_temp_file("same content")
      {:ok, path2} = create_temp_file("same content")
      hash1 = Hasher.hash_file(path1)
      hash2 = Hasher.hash_file(path2)
      assert hash1 == hash2
      cleanup_temp_file(path1)
      cleanup_temp_file(path2)
    end

    test "returns different hash for different content" do
      {:ok, path1} = create_temp_file("content one")
      {:ok, path2} = create_temp_file("content two")
      hash1 = Hasher.hash_file(path1)
      hash2 = Hasher.hash_file(path2)
      assert hash1 != hash2
      cleanup_temp_file(path1)
      cleanup_temp_file(path2)
    end

    test "hashes empty file" do
      {:ok, path} = create_temp_file("")
      hash = Hasher.hash_file(path)
      assert is_binary(hash)
      assert String.length(hash) == 32
      cleanup_temp_file(path)
    end

    test "hashes large file" do
      large_content = String.duplicate("a", 100_000)
      {:ok, path} = create_temp_file(large_content)
      hash = Hasher.hash_file(path)
      assert is_binary(hash)
      assert String.length(hash) == 32
      cleanup_temp_file(path)
    end

    test "handles special characters in file content" do
      {:ok, path} = create_temp_file("test\ncontent\nwith\t\t\t\ttabs")
      hash = Hasher.hash_file(path)
      assert is_binary(hash)
      assert String.length(hash) == 32
      cleanup_temp_file(path)
    end
  end

  defp create_temp_file(content) do
    path = Path.join(System.tmp_dir(), "test_file_#{System.unique_integer([:positive])}")
    File.write!(path, content)
    {:ok, path}
  end

  defp cleanup_temp_file(path) do
    File.rm(path)
  end
end
