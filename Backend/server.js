require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const User = require('./models/User');
const Workout = require('./models/Workout');
const Nutrition = require('./models/Nutrition');
const Weight = require('./models/Weight');

const app = express();

app.use(cors());
app.use(express.json());

const PORT = 5000;


// ===============================
// MongoDB Connection
// ===============================

mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log('MongoDB connected successfully');
  })
  .catch((error) => {
    console.error('MongoDB connection failed:', error);
  });


// ===============================
// Home Route
// ===============================

app.get('/', (req, res) => {
  res.json({
    message: 'F-Track Backend is running'
  });
});


// ===============================
// Signup API
// ===============================

app.post('/signup', async (req, res) => {
  try {
    const {
      name,
      email,
      mobile,
      password
    } = req.body;

    if (!name || !email || !mobile || !password) {
      return res.status(400).json({
        message: 'All fields are required'
      });
    }

    const existingUser = await User.findOne({
      $or: [
        { email: email },
        { mobile: mobile }
      ]
    });

    if (existingUser) {
      return res.status(400).json({
        message: 'Email or mobile already registered'
      });
    }

    const user = new User({
      name,
      email,
      mobile,
      password
    });

    await user.save();

    res.status(201).json({
      message: 'Signup successful',
      user: {
        name: user.name,
        email: user.email,
        mobile: user.mobile
      }
    });

  } catch (error) {
    console.error('Signup error:', error);

    res.status(500).json({
      message: 'Server error during signup'
    });
  }
});


// ===============================
// Login API
// ===============================

app.post('/login', async (req, res) => {
  try {
    const {
      emailOrMobile,
      password
    } = req.body;

    if (!emailOrMobile || !password) {
      return res.status(400).json({
        message: 'Email/mobile and password are required'
      });
    }

    const user = await User.findOne({
      $or: [
        { email: emailOrMobile },
        { mobile: emailOrMobile }
      ]
    });

    if (!user || user.password !== password) {
      return res.status(401).json({
        message: 'Invalid email/mobile or password'
      });
    }

    res.status(200).json({
      message: 'Login successful',
      user: {
        name: user.name,
        email: user.email,
        mobile: user.mobile,
        age: user.age,
        height: user.height,
        fitnessGoal: user.fitnessGoal
      }
    });

  } catch (error) {
    console.error('Login error:', error);

    res.status(500).json({
      message: 'Server error during login'
    });
  }
});


// ===============================
// Get Profile API
// ===============================

app.get('/profile/:email', async (req, res) => {
  try {
    const email = decodeURIComponent(req.params.email);

    const user = await User.findOne({
      email
    }).select('-password');

    if (!user) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    res.status(200).json({
      user
    });

  } catch (error) {
    console.error('Get profile error:', error);

    res.status(500).json({
      message: 'Server error while getting profile'
    });
  }
});


// ===============================
// Update Profile API
// ===============================

app.put('/profile', async (req, res) => {
  try {
    const {
      email,
      name,
      mobile,
      age,
      height,
      fitnessGoal
    } = req.body;

    if (!email) {
      return res.status(400).json({
        message: 'Email is required'
      });
    }

    const user = await User.findOne({
      email
    });

    if (!user) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    user.name = name ?? user.name;
    user.mobile = mobile ?? user.mobile;
    user.age = age ?? user.age;
    user.height = height ?? user.height;
    user.fitnessGoal = fitnessGoal ?? user.fitnessGoal;

    await user.save();

    res.status(200).json({
      message: 'Profile updated successfully',
      user: {
        name: user.name,
        email: user.email,
        mobile: user.mobile,
        age: user.age,
        height: user.height,
        fitnessGoal: user.fitnessGoal
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);

    res.status(500).json({
      message: 'Server error while updating profile'
    });
  }
});


// ===============================
// WORKOUT APIs
// ===============================


// Save Workout API

app.post('/workouts', async (req, res) => {
  try {
    const {
      userEmail,
      type,
      exercise,
      duration,
      calories,
      date
    } = req.body;

    if (
      !userEmail ||
      !type ||
      !exercise ||
      duration == null ||
      calories == null
    ) {
      return res.status(400).json({
        message: 'All workout fields are required'
      });
    }

    const workout = new Workout({
      userEmail,
      type,
      exercise,
      duration,
      calories,
      date: date || new Date()
    });

    await workout.save();

    res.status(201).json({
      message: 'Workout saved successfully',
      workout
    });

  } catch (error) {
    console.error('Workout save error:', error);

    res.status(500).json({
      message: 'Server error while saving workout'
    });
  }
});


// Get Workouts API

app.get('/workouts/:userEmail', async (req, res) => {
  try {
    const userEmail =
        decodeURIComponent(req.params.userEmail);

    const workouts = await Workout.find({
      userEmail
    }).sort({
      date: -1
    });

    res.status(200).json({
      workouts
    });

  } catch (error) {
    console.error('Get workouts error:', error);

    res.status(500).json({
      message: 'Server error while getting workouts'
    });
  }
});


// Delete Workout API

app.delete('/workouts/:id', async (req, res) => {
  try {
    const workout =
        await Workout.findByIdAndDelete(
          req.params.id
        );

    if (!workout) {
      return res.status(404).json({
        message: 'Workout not found'
      });
    }

    res.status(200).json({
      message: 'Workout deleted successfully'
    });

  } catch (error) {
    console.error('Delete workout error:', error);

    res.status(500).json({
      message: 'Server error while deleting workout'
    });
  }
});


// ===============================
// NUTRITION APIs
// ===============================


// Save Nutrition API

app.post('/nutrition', async (req, res) => {
  try {
    const {
      userEmail,
      meal,
      food,
      calories,
      date
    } = req.body;

    if (
      !userEmail ||
      !meal ||
      !food ||
      calories == null
    ) {
      return res.status(400).json({
        message: 'All nutrition fields are required'
      });
    }

    const nutrition = new Nutrition({
      userEmail,
      meal,
      food,
      calories,
      date: date || new Date()
    });

    await nutrition.save();

    res.status(201).json({
      message: 'Nutrition saved successfully',
      nutrition
    });

  } catch (error) {
    console.error('Nutrition save error:', error);

    res.status(500).json({
      message: 'Server error while saving nutrition'
    });
  }
});


// Get Nutrition API

app.get('/nutrition/:userEmail', async (req, res) => {
  try {
    const userEmail =
        decodeURIComponent(req.params.userEmail);

    const nutrition = await Nutrition.find({
      userEmail
    }).sort({
      date: -1
    });

    res.status(200).json({
      nutrition
    });

  } catch (error) {
    console.error('Get nutrition error:', error);

    res.status(500).json({
      message: 'Server error while getting nutrition'
    });
  }
});


// Delete Nutrition API

app.delete('/nutrition/:id', async (req, res) => {
  try {
    const nutrition =
        await Nutrition.findByIdAndDelete(
          req.params.id
        );

    if (!nutrition) {
      return res.status(404).json({
        message: 'Nutrition entry not found'
      });
    }

    res.status(200).json({
      message: 'Nutrition entry deleted successfully'
    });

  } catch (error) {
    console.error('Delete nutrition error:', error);

    res.status(500).json({
      message: 'Server error while deleting nutrition'
    });
  }
});


// ===============================
// WEIGHT APIs
// ===============================


// Save Weight API

app.post('/weight', async (req, res) => {
  try {
    const {
      userEmail,
      weight,
      date
    } = req.body;

    if (!userEmail || weight == null) {
      return res.status(400).json({
        message: 'User email and weight are required'
      });
    }

    const weightEntry = new Weight({
      userEmail,
      weight,
      date: date || new Date()
    });

    await weightEntry.save();

    res.status(201).json({
      message: 'Weight saved successfully',
      weight: weightEntry
    });

  } catch (error) {
    console.error('Weight save error:', error);

    res.status(500).json({
      message: 'Server error while saving weight'
    });
  }
});


// Get Weight API

app.get('/weight/:userEmail', async (req, res) => {
  try {
    const userEmail =
        decodeURIComponent(req.params.userEmail);

    const weights = await Weight.find({
      userEmail
    }).sort({
      date: -1
    });

    res.status(200).json({
      weights
    });

  } catch (error) {
    console.error('Get weight error:', error);

    res.status(500).json({
      message: 'Server error while getting weight'
    });
  }
});


// Delete Weight API

app.delete('/weight/:id', async (req, res) => {
  try {
    const weight =
        await Weight.findByIdAndDelete(
          req.params.id
        );

    if (!weight) {
      return res.status(404).json({
        message: 'Weight entry not found'
      });
    }

    res.status(200).json({
      message: 'Weight deleted successfully'
    });

  } catch (error) {
    console.error('Delete weight error:', error);

    res.status(500).json({
      message: 'Server error while deleting weight'
    });
  }
});


// ===============================
// START SERVER
// ===============================

app.listen(PORT, () => {
  console.log(
    `Server running on http://localhost:${PORT}`
  );
});