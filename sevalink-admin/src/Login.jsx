import React, { useState } from "react";
import App from "./App";
import { login as apiLogin, forgotPassword, resetPassword, register as apiRegister } from "./api";
import logo from "./assets/logo.png";
import bgImage from "./assets/login-bg.png";

function Login() {

  const [isLoggedIn, setIsLoggedIn] = useState(() => !!localStorage.getItem('accessToken'));
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [birthday, setBirthday] = useState('');
  const [registerError, setRegisterError] = useState(null);
  const [registerMessage, setRegisterMessage] = useState(null);
  const [registerMode, setRegisterMode] = useState(false);
  const [error, setError] = useState(null);
  const [forgotMode, setForgotMode] = useState(false);
  const [resetMode, setResetMode] = useState(false);
  const [resetToken, setResetToken] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [forgotMessage, setForgotMessage] = useState(null);
  const [forgotError, setForgotError] = useState(null);
  const [resetMessage, setResetMessage] = useState(null);
  const [resetError, setResetError] = useState(null);
  const [toastMessage, setToastMessage] = useState(null);
  const [showToast, setShowToast] = useState(false);

  if (isLoggedIn) {
    return <App onLogout={() => {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      setIsLoggedIn(false);
      setEmail('');
      setPassword('');
      setToastMessage('Logout successful. Redirecting to login...');
      setShowToast(true);
      setTimeout(() => setShowToast(false), 1200);
    }} />;
  }

  return (
<div
  className="h-screen w-full bg-cover bg-center flex items-center justify-center relative overflow-hidden"
  style={{ backgroundImage: `url(${bgImage})` }}
>

  {/* DARK OVERLAY */}
  <div className="absolute inset-0 bg-black/50"></div>

  {/* LOGIN CARD */}
 <div className="relative z-10 w-[380px] max-h-[calc(100vh-4rem)] overflow-y-auto bg-white/10 backdrop-blur-xl border border-white/20 rounded-3xl px-7 py-6 shadow-2xl">

    {/* LOGO */}
    <div className="flex flex-col items-center mb-2">

      <img
        src={logo}
        alt="logo"
        className="w-28 h-28 object-contain mb-3"
      />

      <h1 className="text-2xl font-extrabold text-white -mt-4">
        SevaLink
      </h1>

      <p className="text-orange-300 tracking-[3px] text-sm mt-1">
        ADMIN PANEL
      </p>

    </div>

    {/* WELCOME */}
    <div className="text-center mb-2">

      <h2 className="text-2xl font-bold text-white mb-2">
        Welcome Back
      </h2>

      <p className="text-gray-300 text-sm leading-5 mx-auto max-w-[280px]">
        Manage workers, bookings, analytics,
        communication, and platform operations.
      </p>

    </div>

    {!registerMode && !forgotMode && (
      <>
        {/* EMAIL */}
        <div className="mb-4">

        <label className="block text-white mb-2 font-semibold text-base">
            Admin Email
          </label>

          <input
            value={email}
            onChange={e => setEmail(e.target.value)}
            type="email"
            placeholder="Enter your email"
            className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
          />

        </div>

        {/* PASSWORD */}
        <div className="mb-4">

          <label className="block text-white mb-2 font-semibold text-base">
            Password
          </label>

          <input
            value={password}
            onChange={e => setPassword(e.target.value)}
            type="password"
            placeholder="Enter your password"
            className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
          />

        </div>

        {/* OPTIONS */}
        <div className="flex flex-col gap-3 mb-5 text-base">

          <label className="flex items-center gap-3 text-gray-200 text-base">
            Remember me
            <input type="checkbox" className="h-5 w-5" />
          </label>

          <button
            type="button"
            onClick={() => {
              setError(null);
              setRegisterMode(false);
              setRegisterError(null);
              setRegisterMessage(null);
              setForgotMessage(null);
              setForgotError(null);
              setResetMessage(null);
              setResetError(null);
              setResetMode(false);
              setForgotMode(true);
            }}
            className="text-orange-300 hover:text-orange-400 text-left"
          >
            Forgot Password?
          </button>

          <button
            type="button"
            onClick={() => {
              setError(null);
              setForgotMode(false);
              setForgotMessage(null);
              setForgotError(null);
              setRegisterError(null);
              setRegisterMessage(null);
              setRegisterMode(true);
            }}
            className="text-orange-300 hover:text-orange-400 text-left"
          >
            Register Admin
          </button>

      </div>
      </>
    )}

    {registerMode ? (
      <div className="space-y-4 mb-4">
        <div>
          <label className="block text-white mb-2 font-semibold text-base">Full Name</label>
          <input
            value={fullName}
            onChange={e => setFullName(e.target.value)}
            type="text"
            placeholder="Enter full name"
            className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
          />
        </div>
        <div>
          <label className="block text-white mb-2 font-semibold text-base">Email</label>
          <input
            value={email}
            onChange={e => setEmail(e.target.value)}
            type="email"
            placeholder="Enter email"
            className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
          />
        </div>
        <div>
          <label className="block text-white mb-2 font-semibold text-base">Password</label>
          <input
            value={password}
            onChange={e => setPassword(e.target.value)}
            type="password"
            placeholder="Enter password"
            className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
          />
        </div>
        <div>
          <label className="block text-white mb-2 font-semibold text-base">Phone Number</label>
          <input
            value={phoneNumber}
            onChange={e => setPhoneNumber(e.target.value)}
            type="tel"
            placeholder="Enter phone number"
            className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
          />
        </div>
        <div>
          <label className="block text-white mb-2 font-semibold text-base">Birthday</label>
          <input
            value={birthday}
            onChange={e => setBirthday(e.target.value)}
            type="date"
            className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
          />
        </div>
        <button
          type="button"
          onClick={async () => {
            try {
              setRegisterError(null);
              setRegisterMessage(null);
              const user = await apiRegister({
                fullName,
                email,
                phoneNumber,
                birthday,
                password,
                role: 'ADMIN'
              });
              setToastMessage('Registration successful. Redirecting to dashboard...');
              setShowToast(true);
              setRegisterMessage('Registration successful. Redirecting to dashboard...');
              setTimeout(() => {
                setShowToast(false);
                setIsLoggedIn(true);
              }, 1000);
            } catch (e) {
              setRegisterError(e.message);
            }
          }}
          className="w-full bg-green-500 hover:bg-green-600 text-white py-3 rounded-2xl font-bold text-sm transition-all duration-300 shadow-xl"
        >
          Register Admin
        </button>
        <button
          type="button"
          onClick={() => {
            setRegisterMode(false);
            setRegisterError(null);
            setRegisterMessage(null);
          }}
          className="mt-1 w-full text-white text-[11px] underline"
        >
          Back to Sign In
        </button>
        {registerMessage && <p className="text-green-300 mt-1 text-sm">{registerMessage}</p>}
        {registerError && <p className="text-red-300 mt-1 text-sm">{registerError}</p>}
      </div>
    ) : resetMode ? (
      <div className="space-y-4 mb-5">
        <div>
          <label className="block text-white mb-2 font-semibold text-base">Reset PIN</label>
          <input
            value={resetToken}
            onChange={e => setResetToken(e.target.value)}
            type="text"
            placeholder="Enter the PIN from your email"
            className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
          />
        </div>
        <div>
          <label className="block text-white mb-2 font-semibold text-base">New Password</label>
          <input
            value={newPassword}
            onChange={e => setNewPassword(e.target.value)}
            type="password"
            placeholder="Choose a new password"
            className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
          />
        </div>
        <div>
          <label className="block text-white mb-2 font-semibold text-base">Confirm New Password</label>
          <input
            value={confirmPassword}
            onChange={e => setConfirmPassword(e.target.value)}
            type="password"
            placeholder="Repeat new password"
            className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
          />
        </div>
        <button
          type="button"
          onClick={async () => {
            try {
              setResetError(null);
              setResetMessage(null);
              if (!resetToken.trim()) throw new Error('Reset PIN is required');
              if (newPassword.length < 6) throw new Error('Password must be at least 6 characters');
              if (newPassword !== confirmPassword) throw new Error('Passwords do not match');
              await resetPassword(resetToken.trim(), newPassword);
              setResetMessage('Password reset successful. Please sign in with your new password.');
              setResetMode(false);
              setForgotMode(false);
              setPassword('');
              setResetToken('');
              setNewPassword('');
              setConfirmPassword('');
            } catch (e) {
              setResetError(e.message);
            }
          }}
          className="mt-4 w-full bg-green-600 hover:bg-green-700 text-white py-3 rounded-2xl font-bold text-base transition-all duration-300 shadow-xl"
        >
          Reset Password
        </button>
        <button
          type="button"
          onClick={() => {
            setResetMode(false);
            setForgotMode(true);
            setResetError(null);
            setResetMessage(null);
          }}
          className="mt-2 w-full text-white text-sm underline"
        >
          I need a reset PIN instead
        </button>
        <button
          type="button"
          onClick={() => {
            setResetMode(false);
            setForgotMode(false);
            setResetError(null);
            setResetMessage(null);
          }}
          className="mt-2 w-full text-white text-sm underline"
        >
          Back to Sign In
        </button>
        {resetMessage && <p className="text-green-300 mt-3">{resetMessage}</p>}
        {resetError && <p className="text-red-300 mt-3">{resetError}</p>}
      </div>
    ) : forgotMode ? (
      <div className="mb-5">
        <label className="block text-white mb-2 font-semibold text-base">
          Enter your email to reset password
        </label>
        <input
          value={email}
          onChange={e => setEmail(e.target.value)}
          type="email"
          placeholder="Enter your email"
          className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
        />
        <button
          type="button"
          onClick={async () => {
            try {
              setForgotError(null);
              setForgotMessage(null);
              const message = await forgotPassword(email);
              setForgotMessage(message);
            } catch (e) {
              setForgotError(e.message);
            }
          }}
          className="mt-4 w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-2xl font-bold text-base transition-all duration-300 shadow-xl"
        >
          Send Reset PIN
        </button>
        <button
          type="button"
          onClick={() => {
            setForgotMode(false);
            setForgotMessage(null);
            setForgotError(null);
          }}
          className="mt-2 w-full text-white text-sm underline"
        >
          Back to Sign In
        </button>
        <button
          type="button"
          onClick={() => {
            setForgotMode(false);
            setResetMode(true);
            setForgotError(null);
            setForgotMessage(null);
          }}
          className="mt-2 w-full text-white text-sm underline"
        >
          I already have a PIN
        </button>
        {forgotMessage && <p className="text-green-300 mt-3">{forgotMessage}</p>}
        {forgotError && <p className="text-red-300 mt-3">{forgotError}</p>}
      </div>
    ) : (
      <>
        <button
          onClick={async () => {
            try {
              setError(null);
              setToastMessage('Login successful. Redirecting to dashboard...');
              setShowToast(true);
              await apiLogin(email, password);
              setTimeout(() => {
                setShowToast(false);
                setIsLoggedIn(true);
              }, 1000);
            } catch (e) {
              setShowToast(false);
              setError(e.message);
            }
          }}
          className="w-full bg-orange-500 hover:bg-orange-600 text-white py-3 rounded-2xl font-bold text-base transition-all duration-300 shadow-xl"
        >
          Login
        </button>
      </>
    )}
    {error && <p className="text-red-400 mt-2 text-center">{error}</p>}
    <p className="text-center text-gray-300 text-sm mt-6">
      © 2026 SevaLink. All Rights Reserved.
    </p>
  </div>

  {showToast && (
      <div className="fixed bottom-6 right-10 z-50 w-[320px] rounded-2xl bg-green-600/95 px-5 py-4 shadow-2xl text-white ring-1 ring-white/20">
        <h3 className="font-semibold text-sm">Success</h3>
        <p className="text-sm mt-1">{toastMessage}</p>
      </div>
    )}

</div>

  );
}

export default Login;