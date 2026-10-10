
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({

    name: {
        type: String,
        required: true
    },

    email: {
        type: String,
        required: true,
        unique: true
    },

    mobile: {
        type: String,
        required: true,
        unique: true
    },

    password: {
        type: String,
        required: true
    },

    age: {
        type: String,
        default: ''
    },

    height: {
        type: String,
        default: ''
    },

    fitnessGoal: {
        type: String,
        default: 'Stay Fit'
    }

});

module.exports = mongoose.model('User', userSchema);