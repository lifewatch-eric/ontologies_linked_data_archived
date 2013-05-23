require_relative "../test_case"

class TestUserAuthentication < LinkedData::TestCase
  def teardown
    u = LinkedData::Models::User.find("test_user").first
    u.delete unless u.nil?
  end

  def test_auto_password_hash_assignment
    password = "a_password"
    u = LinkedData::Models::User.new({
        username: "test_user",
        email: "test@example.com",
        password: password
      })
    assert_raises NoMethodError do
      assert u.password.nil?
    end
    assert !u.passwordHash.eql?(password)
  end

  def test_authentication
    password = "a_password"
    u = LinkedData::Models::User.new({
        username: "test_user",
        email: "test@example.com",
        password: password
      })
    assert_raises NoMethodError do
      assert u.password.nil?
    end
    assert !u.passwordHash.eql?(password)
    assert u.authenticate(password)
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

    u1 = LinkedData::Models::User.find("test_user").include(:passwordHash).first
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

    u.passwordHash = hash
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
    assert_raises Exception do
      u.passwordHash = "password"
    end
  end

end
