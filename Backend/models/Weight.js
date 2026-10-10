const mongoose = require('mongoose');

const weightSchema = new mongoose.Schema(
  {
    userEmail: {
      type: String,
      required: true
    },

    weight: {
      type: Number,
      required: true
    },

    date: {
      type: Date,
      default: Date.now
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('Weight', weightSchema);