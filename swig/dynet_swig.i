%module dynet_swig

// This module provides java bindings for the dynet C++ code

// Automatically load the library code
%pragma(java) jniclasscode=%{
    static {
        System.loadLibrary("dynet_swig");
    }
%}

// Required header files for compiling wrapped code
%{
#include <vector>
#include <sstream>
#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/text_iarchive.hpp>
#include "model.h"
#include "tensor.h"
#include "dynet.h"
#include "training.h"
#include "expr.h"
#include "rnn.h"
#include "lstm.h"
%}

// Extra C++ code added
%{
namespace dynet {

// Convenience function for testing
static void myInitialize()  {
  char** argv = {NULL};
  int argc = 0;
  initialize(argc, argv);
};
}
%}

// Useful SWIG libraries
%include "std_vector.i"
%include "std_string.i"
%include "std_pair.i"

struct dynet::expr::Expression;

// Declare explicit types for needed instantiations of generic types
namespace std {
  %template(IntVector)        vector<int>;
  //  %template(UnsignedVector)   vector<unsigned>;
  %template(DoubleVector)     vector<double>;
  %template(FloatVector)      vector<float>;
  %template(LongVector)       vector<long>;
  %template(StringVector)     vector<std::string>;
  %template(ExpressionVector) vector<dynet::expr::Expression>;
}

//
// The subset of classes/methods/functions we want to wrap
//

namespace dynet {

// Some declarations etc to keep swig happy
typedef float real;
typedef int RNNPointer;
struct VariableIndex;
/*{
  unsigned t;
  explicit VariableIndex(const unsigned t_): t(t_) {};
};*/
struct Tensor;
struct Node;
struct ParameterStorage;
struct LookupParameterStorage;

// declarations from dynet/dim.h

struct Dim {
  Dim() : nd(0), bd(1) {}
  Dim(const std::vector<long> & x);
  Dim(const std::vector<long> & x, unsigned int b);

  unsigned int size();
};

// declarations from dynet/model.h

// Model wrapper class needs to implement Serializable. We serialize a Model by converting it
// to/from a String and using writeObject/readObject on the String.
%typemap(javainterfaces) dynet::Model "java.io.Serializable"

%typemap(javacode) dynet::Model %{
 private void writeObject(java.io.ObjectOutputStream out) throws java.io.IOException {
    out.defaultWriteObject();
    String s = this.serialize_to_string();
    out.writeObject(s);
 }

 private void readObject(java.io.ObjectInputStream in)
     throws java.io.IOException, java.lang.ClassNotFoundException {
    in.defaultReadObject();
    String s = (String) in.readObject();

    // Deserialization doesn't call the constructor, so the swigCPtr is 0. This means we need to
    // do the constructor work ourselves if we don't want a segfault.
    if (this.swigCPtr == 0) {
        this.swigCPtr = dynet_swigJNI.new_Model();
        this.swigCMemOwn = true;
    }

    this.load_from_string(s);
 }
%}

class Model;
struct Parameter {
  Parameter();
  Parameter(Model* mp, unsigned long index);
  void zero();
  Model* mp;
  unsigned long index;

  Dim dim();
  Tensor* values();

  void set_updated(bool b);
  bool is_updated();

};

struct LookupParameter {
  LookupParameter();
  LookupParameter(Model* mp, unsigned long index);
  LookupParameterStorage* get() const;
  void initialize(unsigned index, const std::vector<float>& val) const;
  void zero();
  Model* mp;
  unsigned long index;
  Dim dim() { return get()->dim; }
  std::vector<Tensor>* values() { return &(get()->values); }
  void set_updated(bool b);
  bool is_updated();
};

/*
struct LookupParameterStorage : public ParameterStorageBase {
  void scale_parameters(float a) override;
  void zero() override;
  void squared_l2norm(float* sqnorm) const override;
  void g_squared_l2norm(float* sqnorm) const override;
  size_t size() const override;
  void initialize(unsigned index, const std::vector<float>& val);
  void accumulate_grad(unsigned index, const Tensor& g);
  void clear();
  void initialize_lookups();
  Dim all_dim;
  Tensor all_values;
  Tensor all_grads;
  Dim dim;
  std::vector<Tensor> values;
  std::vector<Tensor> grads;
  std::unordered_set<unsigned> non_zero_grads;
};
*/

class Model {
 public:
  Model();
  ~Model();
  float gradient_l2_norm() const;
  void reset_gradient();

  Parameter add_parameters(const Dim& d, float scale = 0.0f);
  // Parameter add_parameters(const Dim& d, const ParameterInit & init);
  LookupParameter add_lookup_parameters(unsigned n, const Dim& d);
  // LookupParameter add_lookup_parameters(unsigned n, const Dim& d, const ParameterInit & init);

  size_t parameter_count() const;
};

void save_dynet_model(std::string filename, Model* model);
void load_dynet_model(std::string filename, Model* model);

// extra code to serialize / deserialize strings
%extend Model {
   std::string serialize_to_string() {
       std::ostringstream out;
       boost::archive::text_oarchive oa(out);
       oa << (*($self));
       return out.str();
   }

   void load_from_string(std::string serialized) {
       std::istringstream in;
       in.str(serialized);
       boost::archive::text_iarchive ia(in);
       ia >> (*($self));
   }
};

// declarations from dynet/tensor.h

struct Tensor {
  Dim d;
  float* v;
  std::vector<Tensor> bs;
};

real as_scalar(const Tensor& t);
std::vector<real> as_vector(const Tensor& v);

// declarations from dynet/expr.h

struct ComputationGraph;

namespace expr {
struct Expression {
  ComputationGraph *pg;
  VariableIndex i;
  Expression(ComputationGraph *pg, VariableIndex i) : pg(pg), i(i) { }
  //const Tensor& value() const { return pg->get_value(i); }
};

// %template(ExpressionVector)     ::std::vector<Expression>;

Expression input(ComputationGraph& g, real s);
Expression input(ComputationGraph& g, const real *ps);
Expression input(ComputationGraph& g, const Dim& d, const std::vector<float>& data);
//Expression input(ComputationGraph& g, const Dim& d, const std::vector<float>* pdata);
Expression input(ComputationGraph& g, const Dim& d, const std::vector<unsigned int>& ids, const std::vector<float>& data, float defdata = 0.f);
Expression parameter(ComputationGraph& g, Parameter p);
Expression const_parameter(ComputationGraph& g, Parameter p);
Expression lookup(ComputationGraph& g, LookupParameter p, unsigned index);
//Expression lookup(ComputationGraph& g, LookupParameter p, const unsigned* pindex);
Expression const_lookup(ComputationGraph& g, LookupParameter p, unsigned index);
//Expression const_lookup(ComputationGraph& g, LookupParameter p, const unsigned* pindex);
Expression lookup(ComputationGraph& g, LookupParameter p, const std::vector<unsigned>& indices);
//Expression lookup(ComputationGraph& g, LookupParameter p, const std::vector<unsigned>* pindices);
Expression const_lookup(ComputationGraph& g, LookupParameter p, const std::vector<unsigned>& indices);
//Expression const_lookup(ComputationGraph& g, LookupParameter p, const std::vector<unsigned>* pindices);
Expression zeroes(ComputationGraph& g, const Dim& d);
Expression random_normal(ComputationGraph& g, const Dim& d);

// Rename operators to valid java function names
%rename(exprPlus) operator+;
%rename(exprTimes) operator*;
%rename(exprMinus) operator-;
%rename(exprDivide) operator/;
Expression operator-(const Expression& x);
Expression operator+(const Expression& x, const Expression& y);
Expression operator+(const Expression& x, real y);
Expression operator+(real x, const Expression& y);
Expression operator-(const Expression& x, const Expression& y);
Expression operator-(real x, const Expression& y);
Expression operator-(const Expression& x, real y);
Expression operator*(const Expression& x, const Expression& y);
Expression operator*(const Expression& x, float y);
Expression operator*(float y, const Expression& x); // { return x * y; }
Expression operator/(const Expression& x, float y); // { return x * (1.f / y); }

Expression tanh(const Expression& x);
Expression exp(const Expression& x);
Expression log(const Expression& x);
Expression min(const Expression& x, const Expression& y);
Expression max(const Expression& x, const Expression& y);
Expression dot_product(const Expression& x, const Expression& y);
Expression squared_distance(const Expression& x, const Expression& y);
Expression square(const Expression& x);

Expression select_rows(const Expression& x, const std::vector<unsigned> &rows);
Expression select_cols(const Expression& x, const std::vector<unsigned> &cols);
Expression reshape(const Expression& x, const Dim& d);
Expression pick(const Expression& x, unsigned v);
Expression pickrange(const Expression& x, unsigned v, unsigned u);

Expression noise(const Expression& x, real stddev);
Expression dropout(const Expression& x, real p);
Expression block_dropout(const Expression& x, real p);

Expression softmax(const Expression& x);
Expression log_softmax(const Expression& x);
Expression pickneglogsoftmax(const Expression& x, unsigned v);

template <typename T>
Expression affine_transform(const T& xs);
%template(affine_transform_VE) affine_transform<std::vector<Expression>>;

template <typename T>
Expression concatenate_cols(const T& xs);
%template(concatenate_cols_VE) concatenate_cols<std::vector<Expression>>;

template <typename T>
Expression concatenate(const T& xs);
%template(concatenate_VE) concatenate<std::vector<Expression>>;

/*
template <typename T>
inline Expression affine_transform(const T& xs) { return detail::f<AffineTransform>(xs); }
inline Expression affine_transform(const std::initializer_list<Expression>& xs) { return detail::f<AffineTransform>(xs); }
void AffineTransform::forward_dev_impl(const MyDevice & dev, const vector<const Tensor*>& xs, Tensor& fx) const {
*/


} // namespace expr


// declarations from dynet/dynet.h

struct ComputationGraph {
  ComputationGraph();
  ~ComputationGraph();

  VariableIndex add_input(real s);
  // VariableIndex add_input(const real* ps);
  VariableIndex add_input(const Dim& d, const std::vector<float>& data);
  //VariableIndex add_input(const Dim& d, const std::vector<float>* pdata);
  VariableIndex add_input(const Dim& d, const std::vector<unsigned int>& ids, const std::vector<float>& data, float defdata = 0.f);

  VariableIndex add_parameters(Parameter p);
  VariableIndex add_const_parameters(Parameter p);
  VariableIndex add_lookup(LookupParameter p, const unsigned* pindex);
  VariableIndex add_lookup(LookupParameter p, unsigned index);
  VariableIndex add_lookup(LookupParameter p, const std::vector<unsigned>* pindices);
  // VariableIndex add_lookup(LookupParameter p, const std::vector<unsigned>& indices);
  VariableIndex add_const_lookup(LookupParameter p, const unsigned* pindex);
  VariableIndex add_const_lookup(LookupParameter p, unsigned index);
  VariableIndex add_const_lookup(LookupParameter p, const std::vector<unsigned>* pindices);
  // VariableIndex add_const_lookup(LookupParameter p, const std::vector<unsigned>& indices);

  void clear();
  void checkpoint();
  void revert();

  const Tensor& forward(const expr::Expression& last);
  //const Tensor& forward(VariableIndex i);
  const Tensor& incremental_forward(const expr::Expression& last);
  //const Tensor& incremental_forward(VariableIndex i);
  //const Tensor& get_value(VariableIndex i);
  const Tensor& get_value(const expr::Expression& e);
  void invalidate();
  void backward(const expr::Expression& last);
  //void backward(VariableIndex i);

  void print_graphviz() const;

  std::vector<Node*> nodes;
  std::vector<VariableIndex> parameter_nodes;
};


// declarations from dynet/training.h

// Need to disable constructor as SWIG gets confused otherwise
%nodefaultctor Trainer;
struct Trainer {
  void update(real scale = 1.0);
  void update_epoch(real r = 1);
  void rescale_and_reset_weight_decay();
  real eta0;
  real eta;
  real eta_decay;
  real epoch;
  real clipping_enabled;
  real clip_threshold;
  real clips;
  real updates;
  bool aux_allocated;
  Model* model;
};

struct SimpleSGDTrainer : public Trainer {
  explicit SimpleSGDTrainer(Model& m, real e0 = 0.1, real edecay = 0.0) : Trainer(m, e0, edecay) {}
};

// declarations from dynet/rnn.h

%nodefaultctor RNNBuilder;
struct RNNBuilder {
  RNNPointer state() const;
  void new_graph(ComputationGraph& cg);
  void start_new_sequence(const std::vector<dynet::expr::Expression>& h_0 = {});
  dynet::expr::Expression set_h(const RNNPointer& prev, const std::vector<dynet::expr::Expression>& h_new = {});
  dynet::expr::Expression set_s(const RNNPointer& prev, const std::vector<dynet::expr::Expression>& s_new = {});
  dynet::expr::Expression add_input(const dynet::expr::Expression& x);
  dynet::expr::Expression add_input(const RNNPointer& prev, const dynet::expr::Expression& x);
  std::vector<dynet::expr::Expression> final_s() const;
  std::vector<dynet::expr::Expression> final_h() const;
};

// declarations from dynet/lstm.h

struct LSTMBuilder : public RNNBuilder {
  //LSTMBuilder() = default;
  explicit LSTMBuilder(unsigned layers,
                       unsigned input_dim,
                       unsigned hidden_dim,
                       Model& model);
};

// declarations from dynet/init.h

void initialize(int& argc, char**& argv, bool shared_parameters = false);
void cleanup();


// additional declarations

static void myInitialize();


}






