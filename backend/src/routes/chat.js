import { Router } from 'express';
import { z } from 'zod';
import { answer } from '../services/orchestrator.js';

export const chat = Router();

const ask = z.object({
  message: z.string().min(1).max(4000),
  conversation_id: z.string().optional(),
});

chat.post('/', async (req, res, next) => {
  try {
    const { message, conversation_id } = ask.parse(req.body);
    const result = await answer({ user: req.user, message, conversationId: conversation_id });
    res.locals.leftOurCloud = result.leftOurCloud;
    res.json(result);
  } catch (err) { next(err); }
});
