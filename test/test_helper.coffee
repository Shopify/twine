jQuery = require('jquery')

window.expect = chai.expect
window.assert = chai.assert
window.spy = sinon.spy
window.mock = sinon.mock
window.stub = sinon.stub

mocha.setup('tdd')

setup ->
  window.sandbox = sinon.sandbox.create
    injectInto: @test.ctx
    properties: ["spy", "stub", "mock", "clock", "server", "requests"]
    useFakeTimers: true
    useFakeServer: true

  sandbox.xhrAssertions = 0

teardown ->
  window.sandbox.verifyAndRestore()
  window.sandbox = null
