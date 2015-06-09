express = require 'express'
path = require 'path'
bodyParser = require 'body-parser'
cls = require 'continuation-local-storage'
Sequelize = require 'sequelize'

namespace = cls.createNamespace 'test-namespace'

Sequelize.cls = namespace

seq = new Sequelize 'postgres://root@localhost:5432/sqlz'

User = seq.define 'user',
  firstName:
    type: Sequelize.STRING
    field: 'first_name'

  lastName:
    type: Sequelize.STRING
    field: 'last_name'

  defaultAddress:
    type: Sequelize.STRING
    field: 'default_address'

, freezeTableName: true

Order = seq.define 'order',
  total:
    type: Sequelize.INTEGER

, freezeTableName: true

Address = seq.define 'address',
  address1: Sequelize.STRING
, freezeTableName: true

Order.belongsTo User
Address.belongsTo User

User.hasMany Order
User.hasMany Address

seq.sync().then -> console.log 'Database is synced and ready to go.'

app = express()
app.use bodyParser.urlencoded {extended: false}
app.use express.static(path.join(__dirname, "site"))

server = app.listen 3000, -> console.log 'Server Running'

app.get '/orders', (req, res) ->
  Order.findAll(include: [all: true, nested: true]).then (orders) ->
    res.send orders: JSON.stringify(orders)

app.get '/users', (req, res) ->
  User.findAll(include: [all: true, nested: true]).then (users) ->
    res.send users: JSON.stringify(users)

app.post '/user', (req, res) ->
  data = req.body
  User.create(firstName: data.firstName, lastName: data.lastName)

app.post '/order', (req, res) ->
  data = req.body
  return unless data.total and data.userId

  Order.create total: data.total, userId: data.userId

app.post '/address', (req, res) ->
  data = req.body

  addAddress = seq.transaction (t) ->
    throw new Error('Invalid Data') unless data.userId and data.address1

    User.findOne(where: {id: data.userId}).then (user) ->
      user.defaultAddress = data.address1
      user.save()

    .then (user) ->
      throw new Error("Fail") if data.address1 is "fail"

      address = Address.create address1: data.address1
      return [user, address]

    .spread (user, addr) ->
      user.addAddress(addr)

  # The following could also be written:
  # addAddress(
  #   (result) -> console.log "Address Successfully Added"
  #   (err) -> console.log "ADDRESS FAILED TO ADD", err
  # )


  addAddress.then (result) ->
    console.log "Address Successfully Added"

  .catch (err) ->
    console.log "ADDRESS FAILED TO ADD", err

