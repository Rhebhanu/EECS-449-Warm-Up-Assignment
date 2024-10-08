import:py from mtllm.llms {Anthropic}
import:jac from rag {RagEngine}

glob llm = Anthropic(model_name='claude-2.1'); 

glob rag_engine:RagEngine = RagEngine();

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
}

node Router {
    can 'route the query to the appropriate task type'

    classify(message: 'query from the user to be routed.': str) -> ChatType 
    by llm(method="Reason", temperature=0.0);
}

walker infer {
    has message: str;
    has chat_history: list[dict];g

    can init_router with `root entry {
        visit [-->](`?Router) else {
            router_node = here ++> Router();
            router_node ++> RagChat();
            router_node ++> QAChat();
            router_node ++> funnyTalk();
            visit router_node;
        }
    }

    can route with Router entry {
        classification = here.classify(message=self.message);
        
        # Only route to funnyTalk if the message contains the word "funny"
        if "funny" in self.message.lower() {
            visit [-->](`?Chat)(?chat_type==ChatType.FUNNY_TALK);
        } else {
            visit [-->](`?Chat)(?chat_type==classification);
        }
    }
}

node Session {
    has id: str;
    has chat_history: list[dict];
    has status: int = 1;

    can chat with interact entry {
        self.chat_history.append({"role": "user", "content": here.message});
        response = infer(message=here.message, chat_history=self.chat_history) spawn root;
        self.chat_history.append({"role": "assistant", "content": response.response});

        report {
            "response": response.response
        };
    }
}

enum ChatType {
    RAG: 'Need to use Retrievable information in specific documents to respond' = "RAG",
    QA: 'Given context is enough for an answer' = "QA",
    FUNNY_TALK: 'Engaging the user in a funny conversation' = "FUNNY_TALK" #used to have more silly conversations
}

node Chat {
    has chat_type: ChatType;
}

node RagChat :Chat: {
    has chat_type: ChatType = ChatType.RAG;

    can respond with infer entry {
        can 'Respond to message using chat_history as context and agent_role as the goal of the agent'
        respond_with_llm(   message:'current message':str,
                    chat_history: 'chat history':list[dict],
                    agent_role:'role of the agent responding':str,
                    context:'retirved context from documents':list
                        ) -> 'response':str by llm();
        data = rag_engine.get_from_chroma(query=here.message);
        here.response = respond_with_llm(here.message, here.chat_history, "You are a conversation agent designed to help users with their queries based on the documents provided", data);
    }
}

node QAChat :Chat: {
    has chat_type: ChatType = ChatType.QA;

    can respond with infer entry {
        can 'Respond to message using chat_history as context and agent_role as the goal of the agent'
        respond_with_llm(   message:'current message':str,
            chat_history: 'chat history':list[dict],
            agent_role:'role of the agent responding':str
                ) -> 'response':str by llm();
        here.response = respond_with_llm(here.message, here.chat_history, agent_role="You are a conversation agent designed to help users with their queries");
    }
}

#Can engage in funny/humerous conversations
node funnyTalk :Chat: {
    has chat_type: ChatType = ChatType.FUNNY_TALK;

    can respond with infer entry {
        can 'Engaging the user with a funny conversation'
        respond_with_llm(
            message: 'current message': str,
            chat_history: 'chat history': list[dict],
            agent_role: 'role of the agent responding': str
        ) -> 'response': str by llm();

        here.response = respond_with_llm(
            message=here.message,
            chat_history=here.chat_history,
            agent_role="You are a friendly chatbot that always aims to inject humor into conversations. Make it funny!"
        );
    }
}
