require_relative "../test_case"

class TestUser < LinkedData::TestCase
  def teardown
    u = LinkedData::Models::User.find("test_user")
    u.delete unless u.nil?
  end

  def test_valid_user
    u = LinkedData::Models::User.new
    assert (not u.valid?)

    u.username = "test_user"
    u.email = "test@example.com"
    assert u.valid?
  end

  def test_user_lifecycle
    u = LinkedData::Models::User.new({
        username: "test_user",
        email: "test@example.com"
      })

    assert_equal false, u.exist?(reload=true)
    u.save
    assert_equal true, u.exist?(reload=true)
    u.delete
    assert_equal false, u.exist?(reload=true)
  end

  def test_user_role_assign
    u = LinkedData::Models::User.new({
        username: "test_user",
        email: "test@example.com",
        role: LinkedData::Models::Users::Role.find("ADMINISTRATOR"),
        password: "a_password"
      })

    assert_equal false, u.exist?(reload=true)
    assert u.valid?
    u.save
    assert u.role.length == 1


    u.role.each do |rr|
      rr.load unless rr.loaded?
    end
    assert_equal u.role.first.role,  "ADMINISTRATOR"
    u.delete
  end

  def test_user_default_datetime
    u = LinkedData::Models::User.new
    #This is nil unless it saves
    #assert u.created.instance_of? DateTime (see goo #65)
    assert u.created.nil?
  end
end
