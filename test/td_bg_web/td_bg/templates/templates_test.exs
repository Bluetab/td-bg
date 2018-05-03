defmodule TdBg.TemplatesTest do
  use TdBg.DataCase

  alias TdBg.Templates

  describe "templates" do
    alias TdBg.Templates.Template

    @valid_attrs %{content: [], name: "some name"}
    @update_attrs %{content: [], name: "some updated name"}
    @invalid_attrs %{content: nil, name: nil}

    def template_fixture(attrs \\ %{}) do
      {:ok, template} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Templates.create_template()

      template
    end

    test "list_templates/0 returns all templates" do
      template = template_fixture()
      assert Templates.list_templates() == [template]
    end

    test "get_template!/1 returns the template with given id" do
      template = template_fixture()
      assert Templates.get_template!(template.id) == template
    end

    test "create_template/1 with valid data creates a template" do
      assert {:ok, %Template{} = template} = Templates.create_template(@valid_attrs)
      assert template.content == []
      assert template.name == "some name"
    end

    test "create_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Templates.create_template(@invalid_attrs)
    end

    test "update_template/2 with valid data updates the template" do
      template = template_fixture()
      assert {:ok, template} = Templates.update_template(template, @update_attrs)
      assert %Template{} = template
      assert template.content == []
      assert template.name == "some updated name"
    end

    test "update_template/2 with invalid data returns error changeset" do
      template = template_fixture()
      assert {:error, %Ecto.Changeset{}} = Templates.update_template(template, @invalid_attrs)
      assert template == Templates.get_template!(template.id)
    end

    test "delete_template/1 deletes the template" do
      template = template_fixture()
      assert {:ok, %Template{}} = Templates.delete_template(template)
      assert_raise Ecto.NoResultsError, fn -> Templates.get_template!(template.id) end
    end

    test "change_template/1 returns a template changeset" do
      template = template_fixture()
      assert %Ecto.Changeset{} = Templates.change_template(template)
    end
  end

  describe "domain templates" do
    alias TdBg.Taxonomies

    @domain_attrs %{description: "some description", name: "some name"}
    @empty_template_attrs %{content: [], name: "some name"}
    @other_empty_template_attrs %{content: [], name: "other name"}

    test "add_templates_to_domain/2 and get_domain_templates/1 adds empty template to a domain" do
      {:ok, template} = Templates.create_template(@empty_template_attrs)
      {:ok, domain} = Taxonomies.create_domain(@domain_attrs)
      Templates.add_templates_to_domain(domain, [template])
      [stored_template] = Templates.get_domain_templates(domain)
      assert template == stored_template
    end

    test "add_templates_to_domain/2 and get_domain_templates/1 adds two templates to a domain" do
      {:ok, template1} = Templates.create_template(@empty_template_attrs)
      {:ok, template2} = Templates.create_template(@other_empty_template_attrs)
      {:ok, domain} = Taxonomies.create_domain(@domain_attrs)
      Templates.add_templates_to_domain(domain, [template1, template2])
      stored_templates = Templates.get_domain_templates(domain)
      assert [template1, template2] == stored_templates
    end

    test "delete_template/1 deletes template with related domain" do
      {:ok, template} = Templates.create_template(@empty_template_attrs)
      {:ok, domain} = Taxonomies.create_domain(@domain_attrs)
      Templates.add_templates_to_domain(domain, [template])
      assert_raise Ecto.ConstraintError, fn -> Templates.delete_template(template) end
    end

  end
end
