"""
LLM Engine for Chatbot Inference supporting Apple Silicon MPS, CUDA, and CPU.
Supports both non-streaming and Server-Sent Event (SSE) streaming token generation with TextIteratorStreamer.
"""

import os
import sys
import time
import threading
from typing import List, Dict, Any, Generator, Optional
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, TextIteratorStreamer

# Add ai-chatbot to path if needed
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.abspath(os.path.join(current_dir, "..", ".."))
root_dir = os.path.abspath(os.path.join(backend_dir, ".."))
if root_dir not in sys.path:
    sys.path.insert(0, root_dir)

from backend.app.config import settings

class LLMEngine:
    _instance: Optional["LLMEngine"] = None

    def __init__(self):
        self.device = self._detect_device()
        self.base_model_name = settings.BASE_MODEL_NAME
        self.lora_dir = settings.LORA_ADAPTER_DIR
        self.tokenizer = None
        self.model = None
        self.is_lora_loaded = False
        self._load_model_and_tokenizer()

    @classmethod
    def get_instance(cls) -> "LLMEngine":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def _detect_device(self) -> str:
        if settings.DEVICE != "auto":
            return settings.DEVICE
        if torch.backends.mps.is_available():
            return "mps"
        elif torch.cuda.is_available():
            return "cuda"
        else:
            return "cpu"

    def _load_model_and_tokenizer(self):
        print(f"[LLMEngine] Initializing model '{self.base_model_name}' on device '{self.device}'...")
        self.tokenizer = AutoTokenizer.from_pretrained(
            self.base_model_name,
            trust_remote_code=True
        )
        if self.tokenizer.pad_token is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token

        # Select efficient precision
        dtype = torch.float16 if self.device in ["mps", "cuda"] else torch.float32

        base_model = AutoModelForCausalLM.from_pretrained(
            self.base_model_name,
            dtype=dtype,
            trust_remote_code=True,
            low_cpu_mem_usage=True
        )

        # Check for fine-tuned LoRA adapter
        adapter_config_path = os.path.join(self.lora_dir, "adapter_config.json")
        if os.path.exists(adapter_config_path):
            try:
                from peft import PeftModel
                print(f"[LLMEngine] Attaching trained LoRA adapter from {self.lora_dir}...")
                self.model = PeftModel.from_pretrained(base_model, self.lora_dir)
                self.is_lora_loaded = True
                print("[LLMEngine] LoRA adapter attached successfully!")
            except Exception as e:
                print(f"[LLMEngine] Warning: Could not load LoRA adapter ({e}), using base model.")
                self.model = base_model
                self.is_lora_loaded = False
        else:
            print("[LLMEngine] No LoRA checkpoint found yet; operating with pretrained base model.")
            self.model = base_model
            self.is_lora_loaded = False

        self.model.to(self.device)
        self.model.eval()
        print(f"[LLMEngine] Model ready on {self.device}. LoRA active: {self.is_lora_loaded}")

    def reload_lora_if_available(self) -> bool:
        """Dynamically attach LoRA adapter once training finishes without server restart."""
        adapter_config_path = os.path.join(self.lora_dir, "adapter_config.json")
        if not os.path.exists(adapter_config_path):
            return False
        if self.is_lora_loaded:
            return True
        try:
            from peft import PeftModel
            print(f"[LLMEngine] Dynamically attaching newly trained LoRA adapter from {self.lora_dir}...")
            base_model = getattr(self.model, "base_model", self.model)
            if hasattr(base_model, "model"):
                base_model = base_model.model
            self.model = PeftModel.from_pretrained(base_model, self.lora_dir)
            self.model.to(self.device)
            self.model.eval()
            self.is_lora_loaded = True
            print("[LLMEngine] Dynamically attached LoRA adapter!")
            return True
        except Exception as e:
            print(f"[LLMEngine] Error dynamically loading LoRA adapter: {e}")
            return False

    def build_prompt(self, messages: List[Dict[str, str]], system_prompt: Optional[str] = None) -> str:
        """Formats conversational messages using model's official ChatML template."""
        formatted_messages = []
        effective_system = system_prompt or settings.DEFAULT_SYSTEM_PROMPT
        formatted_messages.append({"role": "system", "content": effective_system})

        for msg in messages:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if role in ["user", "assistant"]:
                formatted_messages.append({"role": role, "content": content})

        if hasattr(self.tokenizer, "apply_chat_template"):
            prompt = self.tokenizer.apply_chat_template(
                formatted_messages,
                tokenize=False,
                add_generation_prompt=True
            )
        else:
            # Fallback ChatML format
            prompt = ""
            for m in formatted_messages:
                prompt += f"<|im_start|>{m['role']}\n{m['content']}<|im_end|>\n"
            prompt += "<|im_start|>assistant\n"
        return prompt

    def generate(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_new_tokens: int = 512,
        system_prompt: Optional[str] = None
    ) -> Dict[str, Any]:
        """Generate a complete response synchronously with performance metrics."""
        self.reload_lora_if_available()
        prompt = self.build_prompt(messages, system_prompt)
        inputs = self.tokenizer(prompt, return_tensors="pt").to(self.device)
        input_length = inputs["input_ids"].shape[1]

        start_time = time.time()
        do_sample = temperature > 0.05
        with torch.no_grad():
            output_ids = self.model.generate(
                **inputs,
                max_new_tokens=max_new_tokens,
                temperature=temperature if do_sample else 1.0,
                do_sample=do_sample,
                top_p=0.9 if do_sample else 1.0,
                pad_token_id=self.tokenizer.pad_token_id,
                eos_token_id=self.tokenizer.eos_token_id
            )

        elapsed = time.time() - start_time
        gen_tokens = output_ids[0][input_length:]
        response_text = self.tokenizer.decode(gen_tokens, skip_special_tokens=True).strip()
        num_generated = len(gen_tokens)
        tps = round(num_generated / max(0.001, elapsed), 2)

        return {
            "response": response_text,
            "metrics": {
                "generated_tokens": num_generated,
                "latency_seconds": round(elapsed, 3),
                "tokens_per_second": tps,
                "model": self.base_model_name,
                "lora_active": self.is_lora_loaded,
                "device": self.device
            }
        }

    def generate_stream(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_new_tokens: int = 512,
        system_prompt: Optional[str] = None
    ) -> Generator[Dict[str, Any], None, None]:
        """
        Yields tokens incrementally as they are generated by running model.generate()
        on a background thread and reading through TextIteratorStreamer.
        """
        self.reload_lora_if_available()
        prompt = self.build_prompt(messages, system_prompt)
        inputs = self.tokenizer(prompt, return_tensors="pt").to(self.device)
        input_length = inputs["input_ids"].shape[1]

        streamer = TextIteratorStreamer(
            self.tokenizer,
            timeout=30.0,
            skip_prompt=True,
            skip_special_tokens=True
        )

        do_sample = temperature > 0.05
        generate_kwargs = dict(
            **inputs,
            streamer=streamer,
            max_new_tokens=max_new_tokens,
            temperature=temperature if do_sample else 1.0,
            do_sample=do_sample,
            top_p=0.9 if do_sample else 1.0,
            pad_token_id=self.tokenizer.pad_token_id,
            eos_token_id=self.tokenizer.eos_token_id
        )

        thread = threading.Thread(target=self.model.generate, kwargs=generate_kwargs)
        start_time = time.time()
        thread.start()

        token_count = 0
        full_text = []

        for new_text in streamer:
            if new_text:
                token_count += 1
                full_text.append(new_text)
                yield {
                    "event": "delta",
                    "delta": new_text
                }

        thread.join()
        elapsed = time.time() - start_time
        tps = round(token_count / max(0.001, elapsed), 2)

        yield {
            "event": "done",
            "full_text": "".join(full_text).strip(),
            "metrics": {
                "generated_tokens": token_count,
                "latency_seconds": round(elapsed, 3),
                "tokens_per_second": tps,
                "model": self.base_model_name,
                "lora_active": self.is_lora_loaded,
                "device": self.device
            }
        }

    def get_info(self) -> Dict[str, Any]:
        """Return engine metadata and hardware specs."""
        return {
            "base_model": self.base_model_name,
            "device": self.device,
            "lora_active": self.is_lora_loaded,
            "lora_path": self.lora_dir if self.is_lora_loaded else None,
            "torch_version": torch.__version__,
            "apple_silicon_mps": torch.backends.mps.is_available()
        }
