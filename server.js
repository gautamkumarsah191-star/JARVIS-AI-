import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

const app = express();
const PORT = Number(process.env.PORT || 8787);
const API_KEY = process.env.XAI_API_KEY;
const MODEL = process.env.XAI_MODEL;

app.disable('x-powered-by');
app.use(helmet());
const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
  .split(',').map((value) => value.trim()).filter(Boolean);
app.use(cors({
  origin(origin, callback) {
    // Native Android clients generally do not send an Origin header.
    if (!origin || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error('Origin is not allowed by CORS.'));
  },
}));
app.use(express.json({ limit: '256kb' }));
app.use('/api/', rateLimit({
  windowMs: 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Too many requests. Please wait a moment and try again.' },
}));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'JARVIS backend' });
});

app.post('/api/chat', async (req, res) => {
  if (!API_KEY || !MODEL) {
    return res.status(503).json({
      error: 'Backend is not configured. Set XAI_API_KEY and XAI_MODEL in backend/.env.',
    });
  }

  const messages = req.body?.messages;
  if (!Array.isArray(messages) || messages.length === 0 || messages.length > 40 ||
      !messages.every((m) =>
        m && ['user', 'assistant'].includes(m.role) &&
        typeof m.content === 'string' && m.content.trim().length > 0 &&
        m.content.length <= 8000)) {
    return res.status(400).json({ error: 'Invalid messages payload.' });
  }

  const systemMessage = {
    role: 'system',
    content: 'You are JARVIS, a calm, intelligent, professional personal assistant for Gautam. Understand Hindi, English and Hinglish. Reply in the language the user uses. Be helpful, clear, and honest about limitations. Never claim to have performed device actions unless an available integration actually performed them. Ask for confirmation before consequential actions.',
  };

  try {
    const upstream = await fetch('https://api.x.ai/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: MODEL,
        messages: [systemMessage, ...messages],
        temperature: 0.7,
      }),
      signal: AbortSignal.timeout(45000),
    });

    const data = await upstream.json().catch(() => ({}));
    if (!upstream.ok) {
      const providerMessage = data?.error?.message;
      return res.status(502).json({
        error: typeof providerMessage === 'string'
          ? providerMessage.slice(0, 300)
          : `AI provider returned HTTP ${upstream.status}.`,
      });
    }

    const reply = data?.choices?.[0]?.message?.content;
    if (typeof reply !== 'string' || !reply.trim()) {
      return res.status(502).json({ error: 'AI provider returned no text reply.' });
    }
    return res.json({ reply });
  } catch (error) {
    const timedOut = error?.name === 'TimeoutError' || error?.name === 'AbortError';
    return res.status(502).json({
      error: timedOut ? 'AI provider timed out. Please try again.' : 'Could not reach AI provider.',
    });
  }
});

app.use((error, _req, res, _next) => {
  if (error?.message === 'Origin is not allowed by CORS.') {
    return res.status(403).json({ error: 'This origin is not allowed.' });
  }
  return res.status(400).json({ error: 'Invalid request.' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`JARVIS backend listening on port ${PORT}`);
});
