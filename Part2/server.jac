import:py from mtllm.llms {Anthropic}
import:jac from rag {RagEngine}

glob llm = Anthropic(model_name='claude-2.1'); 

glob rag_engine:RagEngine = RagEngine();

node Session {
    has id: str;
    has chat_history: list[dict];
    has status: int = 1;

    can 'Respond to message using chat_history as context and agent_role as the goal of the agent'
    llm_chat(
        message:'current message':str,
        chat_history: 'chat history':list[dict],
        agent_role:'role of the agent responding':str,
        context:'retrieved context from documents':list
    ) -> 'response':str by llm();
}

walker interact {
    has message: str;
    has session_id: str;

    can init_session with `root entry {
         visit [-->](`?Session)(?id == self.session_id) else {
            session_node = here ++> Session(id=self.session_id, chat_history=[], status=1);
            print("Session Node Created");

            visit session_node;
        }
    }

    can chat with Session entry {
        here.chat_history.append({"role": "user", "content": self.message});
        data = rag_engine.get_from_chroma(query=self.message);
        response = here.llm_chat(
            message=self.message,
            chat_history=here.chat_history,
            agent_role="You are a conversation agent designed to help users with their queries based on the documents provided",
            context=data
        );

        here.chat_history.append({"role": "assistant", "content": response});

        report {"response": response};
    }
}


# import:py from transformers {pipeline}  # Import the Hugging Face Transformers pipeline
# import:jac from rag {RagEngine}

# # Initialize a globally accessible Hugging Face pipeline with GPT-Neo
# glob llm = pipeline(task="text-generation", model="EleutherAI/gpt-neo-2.7B");

# glob rag_engine:RagEngine = RagEngine();

# node Session {
#     has id: str;
#     has chat_history: list[dict];
#     has status: int = 1;

#     # Use the Hugging Face pipeline to respond to a message
#     can 'Respond to message using chat_history as context and agent_role as the goal of the agent'
#     llm_chat(
#         message: 'current message': str,
#         chat_history: 'chat history': list[dict],
#         agent_role: 'role of the agent responding': str,
#         context: 'retrieved context from documents': list
#     ) -> 'response': str by llm()
# }

# walker interact {
#     has message: str;
#     has session_id: str;

#     can init_session with `root entry {
#         visit [-->](`?Session)(?id == self.session_id) else {
#             session_node = here ++> Session(id=self.session_id, chat_history=[], status=1);
#             print("Session Node Created");

#             visit session_node;
#         }
#     }

#     can chat with Session entry {
#         here.chat_history.append({"role": "user", "content": self.message});
#         data = rag_engine.get_from_chroma(query=self.message);
        
#         # Generate a response using the Hugging Face GPT-Neo model
#         response = here.llm_chat(
#             message=self.message,
#             chat_history=here.chat_history,
#             agent_role="You are a conversation agent designed to help users with their queries based on the documents provided",
#             context=data
#         );

#         here.chat_history.append({"role": "assistant", "content": response});
        
#         report {"response": response};
#     }
# }
