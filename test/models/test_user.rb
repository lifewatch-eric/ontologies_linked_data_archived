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
    u.password = "a_password"
    assert u.valid?
  end

  def test_user_lifecycle
    u = LinkedData::Models::User.new({
        username: "test_user",
        email: "test@example.com",
        password: "a_password"
      })

    assert_equal false, u.exist?(reload=true)
    assert u.valid?
    u.save
    assert_equal true, u.exist?(reload=true)
    u.delete
    assert_equal false, u.exist?(reload=true)
  end

  def test_auto_password_hash_assignment
    password = "a_password"
    u = LinkedData::Models::User.new({
        username: "test_user",
        email: "test@example.com",
        password: password
      })
    assert u.password.nil?
    assert !u.passwordHash.eql?(password)
  end

  def test_hash_storage
    password = "a_password"
    u = LinkedData::Models::User.new({
        username: "test_user",
        email: "test@example.com",
        password: password
      })
    hash = u.passwordHash
    assert u.valid?
    u.save

    u1 = LinkedData::Models::User.find("test_user")
    assert hash.eql?(u1.passwordHash)
  end

  def test_update_hash
    # SHA256 hash and password from old Java system
    hash = "Pa7ZL/klD1M681Hx+0kZrjVwx5Eq9PsoAtII7XR+xWR0p90lgOE37hzXx1u7WiFF"
    pass = "123456789123456789123456789"

    u = LinkedData::Models::User.new({
        username: "test_user",
        email: "test@example.com"
      })

    u.attributes[:passwordHash] = hash
    assert u.valid?
    u.save

    assert u.passwordHash.eql?(hash)
    assert (not u.valid_password?(pass, u.passwordHash))
    assert u.authenticate(pass)
    assert u.valid_password?(pass, u.passwordHash)
  end

  def test_hash_not_assignable
    skip("Waiting for read-only attribute support...")
    u = LinkedData::Models::User.new
    assert_raise Exception do
      binding.pry
      u.passwordHash = "password"
    end
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
