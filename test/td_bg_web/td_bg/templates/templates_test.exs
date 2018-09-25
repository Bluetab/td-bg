defmodule TdBg.TemplatesTest do
  use TdBg.DataCase

  alias TdBg.Templates

  describe "templates" do
    alias TdBg.Templates.Template

    @valid_attrs   %{content: [],  label: "some name", name: "some_name", is_default: false}
    @update_attrs  %{content: [],  label: "some updated name", name: "some_name", is_default: false}
    @invalid_attrs %{content: nil, label: nil, name: nil}

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
      assert template.label == "some name"
      assert template.name == "some_name"
    end

    test "create_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Templates.create_template(@invalid_attrs)
    end

    test "update_template/2 with valid data updates the template" do
      template = template_fixture()
      assert {:ok, template} = Templates.update_template(template, @update_attrs)
      assert %Template{} = template
      assert template.content == []
      assert template.label == "some updated name"
      assert template.name == "some_name"
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

  describe "working with default templates" do

    test "get_default_template/1 gets default template" do
      insert(:template, label: "label_1", name: "name_1", is_default: false)
      template_2 = insert(:template, label: "label_2", name: "name_2", is_default: true)

      default_template = Templates.get_default_template()
      assert default_template.id == template_2.id
    end

    test "get_default_template/1 gets nil template when no one is default" do
      insert(:template, label: "label_1", name: "name_1", is_default: false)
      insert(:template, label: "label_2", name: "name_2", is_default: false)

      assert Templates.get_default_template() == nil
    end

    test "update_template/1 avoid taking is_default" do
      template_1 = insert(:template, label: "label_1", name: "name_1", is_default: true)
      template_2 = insert(:template, label: "label_2", name: "name_2", is_default: false)

      assert {:ok, _} = Templates.update_template(template_1, %{is_default: true})

      template_1 = Templates.get_template_by_name(template_1.name)
      template_2 = Templates.get_template_by_name(template_2.name)

      assert template_1.is_default
      assert !template_2.is_default
    end

  end

  describe "domain templates" do
    alias TdBg.Taxonomies

    @domain_attrs_child %{description: "some description", label: "some name child", name: "some_name_child"}
    @domain_attrs_parent %{description: "some description", label: "some name parent", name: "some_name_parent"}
    @empty_template_attrs %{content: [], label: "some name", name: "some_name", is_default: false}
    @other_empty_template_attrs %{content: [], label: "other name", name: "other_name", is_default: false}

    test "add_templates_to_domain/2 and get_domain_templates/1 adds empty template to a domain" do
      {:ok, template} = Templates.create_template(@empty_template_attrs)
      {:ok, domain} = Taxonomies.create_domain(@domain_attrs_child)
      Templates.add_templates_to_domain(domain, [template])
      [stored_template] = Templates.get_domain_templates(domain)
      assert template == stored_template
    end

    test "add_templates_to_domain/2 and get_domain_templates/1 adds two templates to a domain" do
      {:ok, template1} = Templates.create_template(@empty_template_attrs)
      {:ok, template2} = Templates.create_template(@other_empty_template_attrs)
      {:ok, domain} = Taxonomies.create_domain(@domain_attrs_child)
      Templates.add_templates_to_domain(domain, [template1, template2])
      stored_templates = Templates.get_domain_templates(domain)
      assert [template1, template2] == stored_templates
    end

    test "add_templates_to_domain_parent/2 and get_domain_templates/1 adds empty template to a domain" do
      {:ok, template} = Templates.create_template(@empty_template_attrs)
      {:ok, domain_parent} = Taxonomies.create_domain(@domain_attrs_parent)
      {:ok, domain} = Taxonomies.create_domain(Map.put(@domain_attrs_child, :parent_id, domain_parent.id))
      Templates.add_templates_to_domain(domain_parent, [template])
      [stored_template] = Templates.get_domain_templates(domain)
      assert template == stored_template
    end

    test "add_multiple_templates_to_domain_parent/2 and get_domain_templates_unique/1 adds empty template to a domain" do
      {:ok, template} = Templates.create_template(@empty_template_attrs)
      {:ok, domain_parent} = Taxonomies.create_domain(@domain_attrs_parent)
      {:ok, domain} = Taxonomies.create_domain(Map.put(@domain_attrs_child, :parent_id, domain_parent.id))
      Templates.add_templates_to_domain(domain_parent, [template])
      Templates.add_templates_to_domain(domain, [template])
      stored_template = Templates.get_domain_templates(domain)
      assert [template] == stored_template
    end

  end
end
