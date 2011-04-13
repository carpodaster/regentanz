# Mocha is unable to stub constants, so we hack around it a bit:
# http://www.danielcadenas.com/2008/09/stubbingmocking-constants-with-mocha.html
class Module #:nodoc:
  def redefine_const(name, value)
    __send__(:remove_const, name) if const_defined?(name)
    const_set(name, value)
  end
end