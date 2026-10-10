
const mongoose = require('mongoose');

const workoutSchema = new mongoose.Schema(
  {
    userEmail: {
      type: String,
      required: true
    },
    type: {
      type: String,
      required: true
    },
    exercise: {
      type: String,
      required: true
    },
    duration: {
      type: Number,
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
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('Workout', workoutSchema);