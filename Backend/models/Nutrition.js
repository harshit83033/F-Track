const mongoose = require('mongoose');

const nutritionSchema = new mongoose.Schema({
  userEmail: {
    type: String,
    required: true
  },

  meal: {
    type: String,
    required: true
  },

  food: {
    type: String,
    required: true
  },

  calories: {
    type: Number,
    required: true
  },

  date: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Nutrition', nutritionSchema);