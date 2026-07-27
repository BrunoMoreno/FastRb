require "fastrb"

RSpec.describe RubyAPI::Router do
  subject(:router) { described_class.new }

  describe "basic routing" do
    it "registers and finds GET routes" do
      router.add_route(:GET, "/users") { "users" }
      route = router.find(:GET, "/users")
      expect(route).not_to be_nil
      expect(route[:method]).to eq(:GET)
    end

    it "registers and finds POST routes" do
      router.add_route(:POST, "/users") { "create" }
      route = router.find(:POST, "/users")
      expect(route).not_to be_nil
    end

    it "registers and finds PUT routes" do
      router.add_route(:PUT, "/users/1") { "update" }
      route = router.find(:PUT, "/users/1")
      expect(route).not_to be_nil
    end

    it "registers and finds PATCH routes" do
      router.add_route(:PATCH, "/users/1") { "patch" }
      route = router.find(:PATCH, "/users/1")
      expect(route).not_to be_nil
    end

    it "registers and finds DELETE routes" do
      router.add_route(:DELETE, "/users/1") { "delete" }
      route = router.find(:DELETE, "/users/1")
      expect(route).not_to be_nil
    end

    it "registers and finds OPTIONS routes" do
      router.add_route(:OPTIONS, "/users") { "options" }
      route = router.find(:OPTIONS, "/users")
      expect(route).not_to be_nil
    end

    it "registers and finds HEAD routes" do
      router.add_route(:HEAD, "/users") { "head" }
      route = router.find(:HEAD, "/users")
      expect(route).not_to be_nil
    end

    it "returns nil for unfound routes" do
      expect(router.find(:GET, "/nonexistent")).to be_nil
    end

    it "returns nil for wrong HTTP method" do
      router.add_route(:GET, "/users") { "users" }
      expect(router.find(:POST, "/users")).to be_nil
    end
  end

  describe "prefix nesting" do
    it "nests routes under a prefix" do
      router.push_prefix("/api")
      router.push_prefix("/v1")
      router.add_route(:GET, "/users") { "users" }
      router.pop_prefix("/v1")
      router.pop_prefix("/api")

      route = router.find(:GET, "/api/v1/users")
      expect(route).not_to be_nil
      expect(route[:path]).to eq("/api/v1/users")
    end

    it "does not leak prefix to other groups" do
      router.push_prefix("/api")
      router.add_route(:GET, "/users") { "users" }
      router.pop_prefix("/api")

      router.push_prefix("/admin")
      router.add_route(:GET, "/users") { "admin_users" }
      router.pop_prefix("/admin")

      expect(router.find(:GET, "/api/users")).not_to be_nil
      expect(router.find(:GET, "/admin/users")).not_to be_nil
    end
  end

  describe "path params" do
    it "extracts param names from path" do
      route = router.add_route(:GET, "/users/:id") { "user" }
      expect(route[:param_names]).to eq([:id])
    end

    it "extracts multiple param names" do
      route = router.add_route(:GET, "/users/:user_id/posts/:id") { "post" }
      expect(route[:param_names]).to eq([:user_id, :id])
    end
  end
end
